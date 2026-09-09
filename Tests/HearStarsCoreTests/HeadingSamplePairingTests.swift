import XCTest
@testable import HearStarsCore

final class HeadingSamplePairingTests: XCTestCase {
    func testWraparoundUsesShortestSignedAngle() throws {
        var pairing = HeadingSamplePairing()
        pairing.record(headingDegrees: 359, at: 10)

        XCTAssertEqual(try XCTUnwrap(pairing.residual(headingDegrees: 1, at: 10)), 2, accuracy: 0.0001)
    }

    func testMatchedStationarySamplesHaveZeroResidual() throws {
        var pairing = HeadingSamplePairing()
        pairing.record(headingDegrees: 42, at: 10)

        XCTAssertEqual(try XCTUnwrap(pairing.residual(headingDegrees: 42, at: 10.05)), 0, accuracy: 0.0001)
    }

    func testTimestampSkewDoesNotReduceResidual() throws {
        var pairing = HeadingSamplePairing()
        pairing.record(headingDegrees: 10, at: 10)

        XCTAssertEqual(try XCTUnwrap(pairing.residual(headingDegrees: 19, at: 10.1)), 9, accuracy: 0.0001)
        XCTAssertEqual(try XCTUnwrap(pairing.residual(headingDegrees: 29, at: 10.1)), 19, accuracy: 0.0001)
    }

    func testRejectsCompassSamplesTooOldOrTooNewForTheMotionStream() {
        var pairing = HeadingSamplePairing()
        pairing.record(headingDegrees: 90, at: 10)

        XCTAssertNil(pairing.residual(headingDegrees: 90, at: 9.89))
        XCTAssertNil(pairing.residual(headingDegrees: 90, at: 10.11))
    }

    func testRejectsInvalidInputWithoutInventingAResidual() throws {
        var pairing = HeadingSamplePairing()
        pairing.record(headingDegrees: 20, at: 1)
        pairing.record(headingDegrees: -1, at: 2)
        pairing.record(headingDegrees: .infinity, at: 3)
        pairing.record(headingDegrees: 30, at: -1)

        XCTAssertEqual(try XCTUnwrap(pairing.residual(headingDegrees: 20, at: 1)), 0, accuracy: 0.0001)
        XCTAssertNil(pairing.residual(headingDegrees: -1, at: 1))
        XCTAssertNil(pairing.residual(headingDegrees: .nan, at: 1))
        XCTAssertNil(pairing.residual(headingDegrees: 20, at: -.infinity))
    }

    func testResetRemovesAllPairingState() {
        var pairing = HeadingSamplePairing()
        pairing.record(headingDegrees: 20, at: 1)
        pairing.reset()

        XCTAssertNil(pairing.residual(headingDegrees: 20, at: 1))
    }

    func testNearVerticalRecordPreventsPairingWithOlderNearbyHeading() {
        var pairing = HeadingSamplePairing()
        pairing.record(headingDegrees: 10, at: 10)
        pairing.record(headingDegrees: nil, at: 10.04)

        XCTAssertNil(pairing.residual(headingDegrees: 10, at: 10.04))
    }

    func testOutOfOrderAndDuplicateRecordsAreIgnoredDeterministically() throws {
        var pairing = HeadingSamplePairing()
        pairing.record(headingDegrees: 10, at: 10)
        pairing.record(headingDegrees: 80, at: 9.99)
        pairing.record(headingDegrees: 70, at: 10)
        pairing.record(headingDegrees: 20, at: 10.05)

        XCTAssertEqual(try XCTUnwrap(pairing.residual(headingDegrees: 10, at: 10)), 0, accuracy: 0.0001)
        XCTAssertEqual(try XCTUnwrap(pairing.residual(headingDegrees: 20, at: 10.05)), 0, accuracy: 0.0001)
    }

    func testRetentionIsLimitedByAgeAndCount() throws {
        var byAge = HeadingSamplePairing()
        byAge.record(headingDegrees: 0, at: 0)
        byAge.record(headingDegrees: 180, at: 2.01)
        XCTAssertNil(byAge.residual(headingDegrees: 0, at: 0))

        var byCount = HeadingSamplePairing()
        byCount.record(headingDegrees: 0, at: 10)
        for index in 1...64 {
            byCount.record(headingDegrees: 180, at: 10 + Double(index) / 1_000)
        }
        XCTAssertEqual(try XCTUnwrap(byCount.residual(headingDegrees: 0, at: 10)), 180, accuracy: 0.0001)
    }

    func testLateMotionDoesNotHideAnEarlierCompassDisagreement() throws {
        var pairing = HeadingSamplePairing()
        pairing.record(headingDegrees: 0, at: 10)
        pairing.record(headingDegrees: 0, at: 10.1)
        pairing.record(headingDegrees: 180, at: 11)

        XCTAssertEqual(try XCTUnwrap(pairing.residual(headingDegrees: 20, at: 10.05)), 20, accuracy: 0.0001)
    }

    func testCompassSampleUsesItsOriginalTimestampDuringAOneSecondSweep() throws {
        var pairing = HeadingSamplePairing()
        for step in 0...10 {
            pairing.record(headingDegrees: Double(step * 9), at: Double(step) / 10)
        }

        // Comparing the compass's 0° sample to the current 90° pose would disagree by 90°.
        XCTAssertEqual(try XCTUnwrap(pairing.residual(headingDegrees: 0, at: 0)), 0, accuracy: 0.0001)
    }
}
