import XCTest
import CoreNetworking

final class PhotoUploaderTests: XCTestCase {
    func testSha256HexOfEmptyData() {
        // Well-known: sha256("") = e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
        let hex = PhotoUploader.sha256Hex(Data())
        XCTAssertEqual(hex, "e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855")
    }

    func testSha256HexOfKnownString() {
        // sha256("abc") = ba7816bf8f01cfea414140de5dae2223b00361a396177a9cb410ff61f20015ad
        let hex = PhotoUploader.sha256Hex(Data("abc".utf8))
        XCTAssertEqual(hex, "ba7816bf8f01cfea414140de5dae2223b00361a396177a9cb410ff61f20015ad")
    }
}
