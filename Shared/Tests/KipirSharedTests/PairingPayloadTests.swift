import XCTest
@testable import KipirShared

final class PairingPayloadTests: XCTestCase {
    func testRoundTrip() throws {
        let payload = PairingPayload(key: PacketCipher.generateKey(), deviceName: "Aydın'ın MacBook Air")
        let parsed = try XCTUnwrap(PairingPayload(string: payload.url.absoluteString))
        XCTAssertEqual(parsed, payload)
        XCTAssertNoThrow(try PacketCipher(key: parsed.key))
    }

    func testURLFormat() throws {
        let payload = PairingPayload(keyData: Data(repeating: 0xFB, count: 32), deviceName: "Mac")
        let components = try XCTUnwrap(URLComponents(url: payload.url, resolvingAgainstBaseURL: false))
        XCTAssertEqual(components.scheme, "kipir")
        XCTAssertEqual(components.host, "pair")

        let key = try XCTUnwrap(components.queryItems?.first { $0.name == "k" }?.value)
        let base64URLAlphabet = CharacterSet.alphanumerics.union(CharacterSet(charactersIn: "-_"))
        XCTAssertTrue(key.unicodeScalars.allSatisfy(base64URLAlphabet.contains))
        XCTAssertEqual(key.count, 43)
    }

    func testRejectsForeignOrBrokenCodes() {
        let key = Data(repeating: 1, count: 32).base64URLEncodedString()
        let invalid = [
            "https://example.com",
            "kipir://other?v=1&k=\(key)&n=Mac",
            "kipir://pair?v=2&k=\(key)&n=Mac",
            "kipir://pair?v=1&k=\(key)",
            "kipir://pair?v=1&k=\(key)&n=",
            "kipir://pair?v=1&k=AAAA&n=Mac",
            "kipir://pair?v=1&k=***&n=Mac",
        ]
        for string in invalid {
            XCTAssertNil(PairingPayload(string: string), string)
        }
    }

    func testBase64URLRoundTripForAllPaddingLengths() {
        for length in 0..<8 {
            let data = Data((0..<length).map { UInt8(truncatingIfNeeded: $0 &* 97 &+ 250) })
            XCTAssertEqual(Data(base64URLEncoded: data.base64URLEncodedString()), data)
        }
    }
}
