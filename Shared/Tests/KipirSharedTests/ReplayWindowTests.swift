import XCTest
@testable import KipirShared

final class ReplayWindowTests: XCTestCase {
    func testAcceptsIncreasingSequences() {
        var window = ReplayWindow()
        for sequence: UInt32 in 1...200 {
            XCTAssertTrue(window.accept(sequence))
        }
    }

    func testRejectsDuplicates() {
        var window = ReplayWindow()
        XCTAssertTrue(window.accept(10))
        XCTAssertFalse(window.accept(10))
        XCTAssertTrue(window.accept(11))
        XCTAssertFalse(window.accept(10))
        XCTAssertFalse(window.accept(11))
    }

    func testAcceptsReorderedPacketsInsideWindow() {
        var window = ReplayWindow()
        XCTAssertTrue(window.accept(100))
        XCTAssertTrue(window.accept(98))
        XCTAssertTrue(window.accept(99))
        XCTAssertFalse(window.accept(98))
        XCTAssertTrue(window.accept(100 - ReplayWindow.size + 1))
    }

    func testRejectsPacketsBehindWindow() {
        var window = ReplayWindow()
        XCTAssertTrue(window.accept(100))
        XCTAssertFalse(window.accept(100 - ReplayWindow.size))
        XCTAssertFalse(window.accept(0))
    }

    func testLargeJumpClearsHistory() {
        var window = ReplayWindow()
        XCTAssertTrue(window.accept(1))
        XCTAssertTrue(window.accept(1_000))
        XCTAssertFalse(window.accept(1_000))
        XCTAssertTrue(window.accept(999))
        XCTAssertFalse(window.accept(1))
    }

    func testReset() {
        var window = ReplayWindow()
        XCTAssertTrue(window.accept(50))
        window.reset()
        XCTAssertTrue(window.accept(50))
        XCTAssertTrue(window.accept(1))
    }
}
