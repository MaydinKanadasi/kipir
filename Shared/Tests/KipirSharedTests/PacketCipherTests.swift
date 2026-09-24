import CryptoKit
import XCTest
@testable import KipirShared

final class PacketCipherTests: XCTestCase {
    func testSealOpenRoundTrip() throws {
        let cipher = try PacketCipher(key: PacketCipher.generateKey())
        let packet = Packet(sequence: 5, message: .move(dx: 2, dy: 3))

        let sealed = try cipher.seal(packet)
        XCTAssertEqual(sealed.count, packet.encoded().count + PacketCipher.overhead)
        XCTAssertEqual(try cipher.openPacket(sealed), packet)
    }

    func testSamePacketSealsDifferently() throws {
        let cipher = try PacketCipher(key: PacketCipher.generateKey())
        let packet = Packet(sequence: 5, timestamp: 1, message: .ping)
        XCTAssertNotEqual(try cipher.seal(packet), try cipher.seal(packet))
    }

    func testTamperedPacketIsRejected() throws {
        let cipher = try PacketCipher(key: PacketCipher.generateKey())
        var sealed = [UInt8](try cipher.seal(Packet(sequence: 1, message: .ping)))
        sealed[sealed.count / 2] ^= 0x01
        XCTAssertThrowsError(try cipher.open(Data(sealed)))
    }

    func testWrongKeyIsRejected() throws {
        let sender = try PacketCipher(key: PacketCipher.generateKey())
        let receiver = try PacketCipher(key: PacketCipher.generateKey())
        let sealed = try sender.seal(Packet(sequence: 1, message: .ping))
        XCTAssertThrowsError(try receiver.open(sealed))
    }

    func testShortInputIsRejected() throws {
        let cipher = try PacketCipher(key: PacketCipher.generateKey())
        XCTAssertThrowsError(try cipher.open(Data([1, 2, 3])))
    }

    func testKeyLengthIsEnforced() {
        XCTAssertThrowsError(try PacketCipher(keyData: Data(count: 16))) { error in
            XCTAssertEqual(error as? PacketCipherError, .invalidKeyLength)
        }
        XCTAssertNoThrow(try PacketCipher(keyData: Data(count: 32)))
    }
}
