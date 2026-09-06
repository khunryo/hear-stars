import XCTest
@testable import HearStarsCore

final class GuidanceMapperTests: XCTestCase {
    func testSignedDegreesUsesNegativeHalfTurnBoundary() {
        XCTAssertEqual(AngleMath.signedDegrees(180), -180, accuracy: 1e-12)
        XCTAssertEqual(AngleMath.signedDegrees(-180), -180, accuracy: 1e-12)
        XCTAssertEqual(AngleMath.signedDegrees(540), -180, accuracy: 1e-12)
    }

    func testAzimuthWrapChoosesTwoDegreesRight() {
        let state = GuidanceMapper.map(
            .init(
                target: .init(azimuthDegrees: 1, altitudeDegrees: 30, localHourAngleDegrees: 0),
                aim: .init(azimuthDegrees: 359, altitudeDegrees: 30),
                headingAccuracyDegrees: 4,
                isMoving: false,
                isSensorFresh: true,
                isPractice: false
            )
        )
        XCTAssertEqual(state.azimuthErrorDegrees, 2, accuracy: 1e-12)
        XCTAssertEqual(state.angularSeparationDegrees, 1.732_028_822, accuracy: 1e-9)
        XCTAssertEqual(state.direction, .aligned)
    }

    func testBadHeadingCanGuideButCannotDiscover() {
        let state = GuidanceMapper.map(
            .init(
                target: .init(azimuthDegrees: 180, altitudeDegrees: 45, localHourAngleDegrees: 0),
                aim: .init(azimuthDegrees: 180, altitudeDegrees: 45),
                headingAccuracyDegrees: 22,
                isMoving: false,
                isSensorFresh: true,
                isPractice: false
            )
        )
        XCTAssertTrue(state.canGuide)
        XCTAssertFalse(state.canDiscover)
        XCTAssertEqual(state.headingQuality, .needsCalibration)
    }

    func testHeadingQualityPhaseOneBoundaries() {
        XCTAssertEqual(GuidanceMapper.headingQuality(nil), .unavailable)
        XCTAssertEqual(GuidanceMapper.headingQuality(-1), .unavailable)
        XCTAssertEqual(GuidanceMapper.headingQuality(8), .good)
        XCTAssertEqual(GuidanceMapper.headingQuality(8.000_001), .fair)
        XCTAssertEqual(GuidanceMapper.headingQuality(10), .fair)
        XCTAssertEqual(GuidanceMapper.headingQuality(10.000_001), .needsCalibration)
        XCTAssertEqual(GuidanceMapper.headingQuality(25), .needsCalibration)
        XCTAssertEqual(GuidanceMapper.headingQuality(25.000_001), .unavailable)
    }

    func testUnavailableHeadingStopsGuidanceAndDiscovery() {
        let state = GuidanceMapper.map(
            .init(
                target: .init(azimuthDegrees: 180, altitudeDegrees: 45, localHourAngleDegrees: 0),
                aim: .init(azimuthDegrees: 180, altitudeDegrees: 45),
                headingAccuracyDegrees: 25.1,
                isMoving: false,
                isSensorFresh: true,
                isPractice: false
            )
        )
        XCTAssertEqual(state.headingQuality, .unavailable)
        XCTAssertFalse(state.canGuide)
        XCTAssertFalse(state.canDiscover)
    }

    func testDiscoveryToleranceIsCappedAtSixDegrees() {
        let state = GuidanceMapper.map(
            .init(
                target: .init(azimuthDegrees: 0, altitudeDegrees: 30, localHourAngleDegrees: 0),
                aim: .init(azimuthDegrees: 0, altitudeDegrees: 30),
                headingAccuracyDegrees: 10,
                isMoving: false,
                isSensorFresh: true,
                isPractice: false
            )
        )
        XCTAssertEqual(state.discoveryToleranceDegrees, 6, accuracy: 1e-12)
    }

    func testMovementStopsGuidanceAndDiscovery() {
        let state = GuidanceMapper.map(
            .init(
                target: .init(azimuthDegrees: 180, altitudeDegrees: 45, localHourAngleDegrees: 0),
                aim: .init(azimuthDegrees: 180, altitudeDegrees: 45),
                headingAccuracyDegrees: 2,
                isMoving: true,
                isSensorFresh: true,
                isPractice: false
            )
        )
        XCTAssertFalse(state.canGuide)
        XCTAssertFalse(state.canDiscover)
    }

    func testGettingCloserMakesGuidanceFasterAndClearer() {
        let target = HorizontalCoordinate(
            azimuthDegrees: 180,
            altitudeDegrees: 45,
            localHourAngleDegrees: 0
        )
        let far = GuidanceMapper.map(
            .init(
                target: target,
                aim: .init(azimuthDegrees: 0, altitudeDegrees: 45),
                headingAccuracyDegrees: 4,
                isMoving: false,
                isSensorFresh: true,
                isPractice: false
            )
        )
        let near = GuidanceMapper.map(
            .init(
                target: target,
                aim: .init(azimuthDegrees: 165, altitudeDegrees: 45),
                headingAccuracyDegrees: 4,
                isMoving: false,
                isSensorFresh: true,
                isPractice: false
            )
        )
        let aligned = GuidanceMapper.map(
            .init(
                target: target,
                aim: .init(azimuthDegrees: 180, altitudeDegrees: 45),
                headingAccuracyDegrees: 4,
                isMoving: false,
                isSensorFresh: true,
                isPractice: false
            )
        )

        XCTAssertLessThan(near.pulseIntervalSeconds, far.pulseIntervalSeconds)
        XCTAssertLessThan(aligned.pulseIntervalSeconds, near.pulseIntervalSeconds)
        XCTAssertGreaterThan(near.clarity, far.clarity)
        XCTAssertGreaterThan(aligned.clarity, near.clarity)
    }

    func testLiveDiscoveryRequiresTwoDegreesAltitudeButPracticeIsExempt() {
        let target = HorizontalCoordinate(azimuthDegrees: 10, altitudeDegrees: 1.999, localHourAngleDegrees: 0)
        let live = GuidanceMapper.map(
            .init(
                target: target,
                aim: .init(azimuthDegrees: 10, altitudeDegrees: 1.999),
                headingAccuracyDegrees: 2,
                isMoving: false,
                isSensorFresh: true,
                isPractice: false
            )
        )
        let practice = GuidanceMapper.map(
            .init(
                target: target,
                aim: .init(azimuthDegrees: 10, altitudeDegrees: 1.999),
                headingAccuracyDegrees: 0,
                isMoving: false,
                isSensorFresh: true,
                isPractice: true
            )
        )
        XCTAssertFalse(live.canDiscover)
        XCTAssertTrue(practice.canDiscover)

        let boundary = GuidanceMapper.map(
            .init(
                target: .init(azimuthDegrees: 10, altitudeDegrees: 2, localHourAngleDegrees: 0),
                aim: .init(azimuthDegrees: 10, altitudeDegrees: 2),
                headingAccuracyDegrees: 2,
                isMoving: false,
                isSensorFresh: true,
                isPractice: false
            )
        )
        XCTAssertTrue(boundary.canDiscover)
    }

    func testZenithAzimuthDisagreementStillReportsAligned() {
        let state = GuidanceMapper.map(
            .init(
                target: .init(azimuthDegrees: 0, altitudeDegrees: 90, localHourAngleDegrees: 0),
                aim: .init(azimuthDegrees: 217, altitudeDegrees: 90),
                headingAccuracyDegrees: 4,
                isMoving: false,
                isSensorFresh: true,
                isPractice: false
            )
        )
        XCTAssertEqual(state.angularSeparationDegrees, 0, accuracy: 1e-12)
        XCTAssertEqual(state.band, .aligned)
        XCTAssertEqual(state.direction, .aligned)
        XCTAssertTrue(state.canDiscover)
    }

    func testOutsideToleranceNeverReportsAlignedFromSmallDiagonalComponents() {
        let state = GuidanceMapper.map(
            .init(
                target: .init(azimuthDegrees: 5, altitudeDegrees: 35, localHourAngleDegrees: 0),
                aim: .init(azimuthDegrees: 0, altitudeDegrees: 30),
                headingAccuracyDegrees: 9,
                isMoving: false,
                isSensorFresh: true,
                isPractice: false
            )
        )
        XCTAssertGreaterThan(state.angularSeparationDegrees, state.discoveryToleranceDegrees)
        XCTAssertNotEqual(state.direction, .aligned)
        XCTAssertFalse(state.canDiscover)
    }

    func testDiscoveryRequiresContinuousHoldAndFiresOnce() {
        var tracker = DiscoveryHoldTracker()
        XCTAssertEqual(tracker.requiredDuration, 0.8, accuracy: 1e-12)
        let start = Date(timeIntervalSince1970: 1_000)
        XCTAssertFalse(tracker.update(isEligible: true, at: start))
        XCTAssertFalse(tracker.update(isEligible: true, at: start.addingTimeInterval(0.79)))
        XCTAssertTrue(tracker.update(isEligible: true, at: start.addingTimeInterval(0.8)))
        XCTAssertFalse(tracker.update(isEligible: true, at: start.addingTimeInterval(2)))

        tracker.reset()
        XCTAssertFalse(tracker.update(isEligible: true, at: start))
        XCTAssertFalse(tracker.update(isEligible: false, at: start.addingTimeInterval(0.5)))
        XCTAssertFalse(tracker.update(isEligible: true, at: start.addingTimeInterval(0.6)))
    }
}
