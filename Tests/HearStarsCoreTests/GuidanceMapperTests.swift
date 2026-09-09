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

    func testApproximateHeadingCanGuideButCannotDiscoverEvenInPractice() {
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
        XCTAssertEqual(state.headingQuality, .approximate)
        let practice = GuidanceMapper.map(
            .init(
                target: .init(azimuthDegrees: 180, altitudeDegrees: 45, localHourAngleDegrees: 0),
                aim: .init(azimuthDegrees: 180, altitudeDegrees: 45),
                headingAccuracyDegrees: 22,
                isMoving: false,
                isSensorFresh: true,
                isPractice: true
            )
        )
        XCTAssertFalse(practice.canDiscover)
    }

    func testHeadingQualityPhaseOneBoundaries() {
        XCTAssertEqual(GuidanceMapper.headingQuality(nil), .unavailable)
        XCTAssertEqual(GuidanceMapper.headingQuality(-1), .unavailable)
        XCTAssertEqual(GuidanceMapper.headingQuality(8), .good)
        XCTAssertEqual(GuidanceMapper.headingQuality(8.000_001), .fair)
        XCTAssertEqual(GuidanceMapper.headingQuality(10), .fair)
        XCTAssertEqual(GuidanceMapper.headingQuality(10.000_001), .approximate)
        XCTAssertEqual(GuidanceMapper.headingQuality(25), .approximate)
        XCTAssertEqual(GuidanceMapper.headingQuality(25.000_001), .unavailable)
        XCTAssertEqual(GuidanceMapper.headingQuality(Double.nan), .unavailable)
        XCTAssertEqual(GuidanceMapper.headingQuality(Double.infinity), .unavailable)
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

    func testApproximateHeadingUsesVicinityWithoutFalseAlignmentOrCloseFeedback() {
        for accuracy in [10.000_001, 14.5, 25.0] {
            let tolerance = min(3.0 + accuracy / 3.0, 6.0)
            let cases: [(name: String, separation: Double, expectedCue: DirectionCue)] = [
                ("inside tolerance", 0, .vicinity),
                ("within reported accuracy", (tolerance + accuracy) / 2, .vicinity),
                ("outside reported accuracy", accuracy + 1, .right)
            ]

            for testCase in cases {
                let state = GuidanceMapper.map(
                    .init(
                        target: .init(
                            azimuthDegrees: testCase.separation,
                            altitudeDegrees: 0,
                            localHourAngleDegrees: 0
                        ),
                        aim: .init(azimuthDegrees: 0, altitudeDegrees: 0),
                        headingAccuracyDegrees: accuracy,
                        isMoving: false,
                        isSensorFresh: true,
                        isPractice: false
                    )
                )

                XCTAssertEqual(state.angularSeparationDegrees, testCase.separation, accuracy: 1e-12)
                XCTAssertEqual(state.headingQuality, .approximate, "accuracy: \(accuracy)")
                XCTAssertEqual(state.direction, testCase.expectedCue, "\(testCase.name), accuracy: \(accuracy)")
                XCTAssertNotEqual(state.direction, .aligned, "\(testCase.name), accuracy: \(accuracy)")
                XCTAssertNotEqual(state.band, .aligned, "\(testCase.name), accuracy: \(accuracy)")
                XCTAssertNotEqual(state.band, .close, "\(testCase.name), accuracy: \(accuracy)")
                XCTAssertGreaterThanOrEqual(state.pulseIntervalSeconds, 0.45)
                XCTAssertLessThanOrEqual(state.clarity, 0.6)
                XCTAssertFalse(state.canDiscover)
            }
        }
    }

    func testApproximateHeadingStillStopsForMovementOrStaleSensors() {
        let moving = GuidanceMapper.map(
            .init(
                target: .init(azimuthDegrees: 180, altitudeDegrees: 45, localHourAngleDegrees: 0),
                aim: .init(azimuthDegrees: 180, altitudeDegrees: 45),
                headingAccuracyDegrees: 14.5,
                isMoving: true,
                isSensorFresh: true,
                isPractice: false
            )
        )
        let stale = GuidanceMapper.map(
            .init(
                target: .init(azimuthDegrees: 180, altitudeDegrees: 45, localHourAngleDegrees: 0),
                aim: .init(azimuthDegrees: 180, altitudeDegrees: 45),
                headingAccuracyDegrees: 14.5,
                isMoving: false,
                isSensorFresh: false,
                isPractice: false
            )
        )
        XCTAssertFalse(moving.canGuide)
        XCTAssertFalse(moving.canDiscover)
        XCTAssertFalse(stale.canGuide)
        XCTAssertFalse(stale.canDiscover)
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

    func testApproximateTransitionResetsDiscoveryHoldWithoutPausingGuidance() {
        var tracker = DiscoveryHoldTracker()
        let start = Date(timeIntervalSince1970: 1_000)
        let ready = guidance(accuracy: 9)
        let approximate = guidance(accuracy: 14.5)

        XCTAssertTrue(ready.canGuide)
        XCTAssertTrue(ready.canDiscover)
        XCTAssertFalse(tracker.update(isEligible: ready.canDiscover, at: start))
        XCTAssertTrue(approximate.canGuide)
        XCTAssertFalse(approximate.canDiscover)
        XCTAssertFalse(tracker.update(isEligible: approximate.canDiscover, at: start.addingTimeInterval(0.4)))
        XCTAssertFalse(tracker.update(isEligible: ready.canDiscover, at: start.addingTimeInterval(0.5)))
        XCTAssertTrue(tracker.update(isEligible: ready.canDiscover, at: start.addingTimeInterval(1.3)))
    }

    private func guidance(accuracy: Double) -> GuidanceState {
        GuidanceMapper.map(
            .init(
                target: .init(azimuthDegrees: 180, altitudeDegrees: 45, localHourAngleDegrees: 0),
                aim: .init(azimuthDegrees: 180, altitudeDegrees: 45),
                headingAccuracyDegrees: accuracy,
                isMoving: false,
                isSensorFresh: true,
                isPractice: false
            )
        )
    }
}
