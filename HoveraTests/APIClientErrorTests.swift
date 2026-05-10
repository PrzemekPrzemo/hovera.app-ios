import XCTest
import CoreNetworking

final class APIClientErrorTests: XCTestCase {
    func testAnyCodableRoundTrip() throws {
        let json = #"{"a":1,"b":"hi","c":null,"d":[true,false],"e":{"k":2.5}}"#
        let decoder = JSONDecoder()
        let any = try decoder.decode(AnyCodable.self, from: Data(json.utf8))

        let encoder = JSONEncoder()
        encoder.outputFormatting = .sortedKeys
        let data = try encoder.encode(any)
        let decoded = try decoder.decode([String: AnyCodable].self, from: data)
        XCTAssertNotNil(decoded["a"])
        XCTAssertNotNil(decoded["b"])
        XCTAssertNotNil(decoded["c"])
        XCTAssertNotNil(decoded["d"])
        XCTAssertNotNil(decoded["e"])
    }
}
