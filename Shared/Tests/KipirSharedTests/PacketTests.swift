import XCTest
@testable import KipirShared

final class PacketTests: XCTestCase {
    private let allMessages: [Message] = [
        .move(dx: 3.5, dy: -12.25),
        .click(ClickEvent(button: .left, phase: .down)),
        .click(ClickEvent(button: .right, phase: .up, clickCount: 2)),
        .scroll(dx: 0, dy: -40),
        .key(scalar: 0x00E7), // ç
        .ping,
        .ack(sequence: 42),
        .pong(pingSequence: 7, pingTimestamp: 123_456_789),
    ]

    func testRoundTripAllMessages() throws {
        for message in allMessages {
            let packet = Packet(sequence: 0xDEAD_BEEF, timestamp: 0x0102_0304_0506_0708, message: message)
            XCTAssertEqual(try Packet(decoding: packet.encoded()), packet, "\(message)")
        }
    }

    func testMovePacketLayout() {
        let packet = Packet(sequence: 1, timestamp: 2, message: .move(dx: 1, dy: -1))
        let bytes = [UInt8](packet.encoded())

        XCTAssertEqual(bytes.count, 21)
        XCTAssertEqual(bytes[0], MessageType.move.rawValue)
        XCTAssertEqual(Array(bytes[1..<5]), [0, 0, 0, 1])
        XCTAssertEqual(Array(bytes[5..<13]), [0, 0, 0, 0, 0, 0, 0, 2])
        XCTAssertEqual(Array(bytes[13..<17]), [0x3F, 0x80, 0x00, 0x00]) // 1.0
        XCTAssertEqual(Array(bytes[17..<21]), [0xBF, 0x80, 0x00, 0x00]) // -1.0
    }

    func testEveryTruncationIsRejected() {
        for message in allMessages {
            let data = Packet(sequence: 1, timestamp: 1, message: message).encoded()
            for length in 0..<data.count {
                XCTAssertThrowsError(try Packet(decoding: data.prefix(length)), "\(message) @\(length)")
            }
        }
    }

    func testUnknownTypeIsRejected() {
        var bytes = [UInt8](Packet(sequence: 1, message: .ping).encoded())
        bytes[0] = 0x7F
        XCTAssertThrowsError(try Packet(decoding: Data(bytes))) { error in
            XCTAssertEqual(error as? PacketCodingError, .unknownMessageType(0x7F))
        }
    }

    func testTrailingBytesAreRejected() {
        let data = Packet(sequence: 1, message: .ping).encoded() + [0]
        XCTAssertThrowsError(try Packet(decoding: data)) { error in
            XCTAssertEqual(error as? PacketCodingError, .trailingBytes)
        }
    }

    func testNonFiniteDeltaIsRejected() {
        let data = Packet(sequence: 1, message: .move(dx: .nan, dy: 0)).encoded()
        XCTAssertThrowsError(try Packet(decoding: data)) { error in
            XCTAssertEqual(error as? PacketCodingError, .invalidValue)
        }
    }

    func testInvalidClickFieldsAreRejected() {
        let valid = [UInt8](Packet(sequence: 1, message: .click(ClickEvent(button: .left, phase: .down))).encoded())
        for (index, badValue) in [(13, UInt8(9)), (14, UInt8(9)), (15, UInt8(0))] {
            var bytes = valid
            bytes[index] = badValue
            XCTAssertThrowsError(try Packet(decoding: Data(bytes)))
        }
    }

    func testInvalidUnicodeScalarIsRejected() {
        let data = Packet(sequence: 1, message: .key(scalar: 0xD800)).encoded()
        XCTAssertThrowsError(try Packet(decoding: data))
    }

    func testRequiresAck() {
        XCTAssertEqual(allMessages.filter(\.requiresAck).map(\.type), [.click, .click, .key])
    }

    func testSequenceCounter() {
        var counter = SequenceCounter()
        XCTAssertEqual(counter.next(), 1)
        XCTAssertEqual(counter.next(), 2)

        var wrapping = SequenceCounter(startingAt: .max)
        XCTAssertEqual(wrapping.next(), .max)
        XCTAssertEqual(wrapping.next(), 0)
    }
}
