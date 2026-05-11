import Foundation
import CryptoKit
import CoreNetworking

/// Uploads photo / document bytes through the presigned-URL flow:
///
///   1. compute sha256 locally
///   2. POST `/api/v1/uploads/horse-photos` with `{sha256, mime, byte_size}`
///      to get `{upload_url, storage_key, headers}`
///   3. PUT bytes to `upload_url` with the returned headers
///   4. return `storage_key` so callers can reference it in their next sync
///      mutation (e.g. `create` on `horse_photos`)
///
/// Failures throw — callers should wrap in retry/requeue if needed.
public actor PhotoUploader {
    public static let shared = PhotoUploader()

    public enum UploadError: Error, Sendable {
        case presignFailed(Error)
        case putFailed(status: Int)
        case transport(URLError)
        case nonHTTPResponse
    }

    public func uploadHorsePhoto(data: Data, mime: String) async throws -> String {
        let sha = Self.sha256Hex(data)
        let presign: PresignResponse
        do {
            presign = try await APIClient.shared.send(
                APIEndpoints.presignHorsePhoto(
                    PresignRequest(sha256: sha, mime: mime, byte_size: data.count)
                )
            )
        } catch {
            throw UploadError.presignFailed(error)
        }

        guard let url = URL(string: presign.upload_url) else {
            throw UploadError.putFailed(status: 0)
        }
        var request = URLRequest(url: url)
        request.httpMethod = presign.method
        for (k, v) in presign.headers {
            request.setValue(v, forHTTPHeaderField: k)
        }
        request.httpBody = data

        do {
            let (_, response) = try await URLSession.shared.data(for: request)
            guard let http = response as? HTTPURLResponse else {
                throw UploadError.nonHTTPResponse
            }
            guard (200..<300).contains(http.statusCode) else {
                throw UploadError.putFailed(status: http.statusCode)
            }
        } catch let urlError as URLError {
            throw UploadError.transport(urlError)
        }
        return presign.storage_key
    }

    public static func sha256Hex(_ data: Data) -> String {
        let digest = SHA256.hash(data: data)
        return digest.map { String(format: "%02x", $0) }.joined()
    }
}
