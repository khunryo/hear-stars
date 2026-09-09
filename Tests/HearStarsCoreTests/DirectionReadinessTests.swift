import XCTest
@testable import HearStarsCore

final class DirectionReadinessTests: XCTestCase {
    func testMissingCompassUpdateWaitsInsteadOfRequestingMagneticCalibration() {
        let accuracies: [Double?] = [nil, 4, 30]
        for accuracy in accuracies {
            for timedOut in [false, true] {
                let state = DirectionReadiness.evaluate(
                    location: .available, directionHardwareAvailable: true,
                    sensorIsFresh: true, headingAccuracyDegrees: accuracy,
                    targetAltitudeDegrees: 35, isMoving: false,
                    preparationHasTimedOut: timedOut, headingIsFresh: false
                )
                assertReadiness(state, timedOut ? .directionDelayed : .checkingDirection)
                XCTAssertFalse(state.canUseDirection)
            }
        }
    }

    func testFreshApproximateCompassCanGuideAfterWaiting() {
        let state = DirectionReadiness.evaluate(
            location: .available, directionHardwareAvailable: true,
            sensorIsFresh: true, headingAccuracyDegrees: 18,
            targetAltitudeDegrees: 35, isMoving: false,
            preparationHasTimedOut: true, headingIsFresh: true
        )
        assertReadiness(state, .approximate)
        XCTAssertTrue(state.canUseDirection)
        XCTAssertFalse(state.canConfirmAlignment)
    }

    func testCalibrationBecomesReadyWhenLiveHeadingImprovesToGoodOrFair() {
        assertReadiness(readiness(headingAccuracyDegrees: nil), .calibrating)
        assertReadiness(readiness(headingAccuracyDegrees: 18), .approximate)
        assertReadiness(readiness(headingAccuracyDegrees: 8), .ready)
        assertReadiness(readiness(headingAccuracyDegrees: 10), .ready)
    }

    func testElapsedPreparationNeverMakesUnavailableHeadingReady() {
        let unusableAccuracies: [Double?] = [nil, -1, 25.000_001, Double.nan, Double.infinity]
        for accuracy in unusableAccuracies {
            for timedOut in [false, true] {
                assertReadiness(
                    readiness(headingAccuracyDegrees: accuracy, preparationHasTimedOut: timedOut),
                    .calibrating
                )
            }
        }
        assertReadiness(readiness(headingAccuracyDegrees: 10.001), .approximate)
        assertReadiness(readiness(headingAccuracyDegrees: 25), .approximate)
        assertReadiness(readiness(headingAccuracyDegrees: 9, preparationHasTimedOut: true), .ready)
    }

    func testReadyIsRevokedAsSoonAsSensorDataStopsAndRecoversWithFreshData() {
        assertReadiness(readiness(), .ready)
        assertReadiness(readiness(sensorIsFresh: false), .checkingDirection)
        assertReadiness(
            readiness(sensorIsFresh: false, preparationHasTimedOut: true),
            .directionDelayed
        )
        assertReadiness(readiness(preparationHasTimedOut: true), .ready)
    }

    func testReadyIsRevokedWhenHeadingDeterioratesAndRecoversWithoutRestart() {
        assertReadiness(readiness(headingAccuracyDegrees: 4), .ready)
        assertReadiness(readiness(headingAccuracyDegrees: 12), .approximate)
        assertReadiness(readiness(headingAccuracyDegrees: nil), .calibrating)
        assertReadiness(readiness(headingAccuracyDegrees: 9), .ready)
    }

    func testScreenshotAccuracyIsApproximateWithoutRelaxingOtherGates() {
        assertReadiness(readiness(headingAccuracyDegrees: 14.5), .approximate)
        assertReadiness(readiness(headingAccuracyDegrees: 14.5, isMoving: true), .moving)
        assertReadiness(readiness(sensorIsFresh: false, headingAccuracyDegrees: 14.5), .checkingDirection)
        assertReadiness(
            readiness(sensorIsFresh: false, headingAccuracyDegrees: 14.5, preparationHasTimedOut: true),
            .directionDelayed
        )
    }

    func testApproximateHeadingPreservesReadinessGates() {
        let cases: [(
            location: DirectionReadiness.LocationState,
            hardwareAvailable: Bool,
            altitude: Double?,
            headingIsFresh: Bool,
            expected: DirectionReadiness
        )] = [
            (.denied, true, 30, true, .locationDenied),
            (.restricted, true, 30, true, .locationRestricted),
            (.permissionRequired, true, 30, true, .locationPermission),
            (.servicesOff, true, 30, true, .locationServicesOff),
            (.waiting, true, 30, true, .locating),
            (.available, false, 30, true, .sensorUnavailable),
            (.available, true, 1.99, true, .belowHorizon),
            (.available, true, nil, true, .locating),
            (.available, true, 30, false, .checkingDirection)
        ]

        for testCase in cases {
            assertReadiness(
                readiness(
                    location: testCase.location,
                    directionHardwareAvailable: testCase.hardwareAvailable,
                    headingAccuracyDegrees: 14.5,
                    targetAltitudeDegrees: testCase.altitude,
                    headingIsFresh: testCase.headingIsFresh
                ),
                testCase.expected
            )
        }
    }

    func testMovementImmediatelyRevokesReadinessAndStoppingRestoresIt() {
        assertReadiness(readiness(), .ready)
        assertReadiness(readiness(isMoving: true), .moving)
        assertReadiness(readiness(isMoving: true, preparationHasTimedOut: true), .moving)
        assertReadiness(readiness(), .ready)
    }

    func testPermissionAndLocationServiceChangesRevokeExistingReadiness() {
        let interruptions: [(DirectionReadiness.LocationState, DirectionReadiness)] = [
            (.denied, .locationDenied),
            (.restricted, .locationRestricted),
            (.servicesOff, .locationServicesOff),
            (.permissionRequired, .locationPermission)
        ]
        for (location, expected) in interruptions {
            assertReadiness(readiness(), .ready)
            assertReadiness(readiness(location: location), expected)
            assertReadiness(readiness(location: location, preparationHasTimedOut: true), expected)
            assertReadiness(readiness(), .ready)
        }
    }

    func testTargetBelowTwoDegreesCannotUseDirectionAndCanRecoverAboveBoundary() {
        assertReadiness(readiness(targetAltitudeDegrees: 20), .ready)
        for altitude in [-10.0, 0, 1.999] {
            assertReadiness(readiness(targetAltitudeDegrees: altitude), .belowHorizon)
            assertReadiness(
                readiness(targetAltitudeDegrees: altitude, preparationHasTimedOut: true),
                .belowHorizon
            )
        }
        assertReadiness(readiness(targetAltitudeDegrees: 2), .ready)
    }

    func testLocationDelayRemainsRecoverableAndDoesNotClaimHardwareIsUnsupported() {
        assertReadiness(readiness(location: .waiting, targetAltitudeDegrees: nil), .locating)
        assertReadiness(
            readiness(location: .waiting, targetAltitudeDegrees: nil, preparationHasTimedOut: true),
            .locationDelayed
        )
        assertReadiness(readiness(preparationHasTimedOut: true), .ready)
    }

    func testMissingTargetObservationWaitsForLocationInsteadOfReportingReady() {
        assertReadiness(readiness(), .ready)
        assertReadiness(readiness(targetAltitudeDegrees: nil), .locating)
        assertReadiness(
            readiness(targetAltitudeDegrees: nil, preparationHasTimedOut: true),
            .locationDelayed
        )
        assertReadiness(readiness(), .ready)
    }

    func testUnsupportedDirectionHardwareDiffersFromAWorkingSensorWaitingForData() {
        for timedOut in [false, true] {
            assertReadiness(
                readiness(directionHardwareAvailable: false, preparationHasTimedOut: timedOut),
                .sensorUnavailable
            )
        }
        assertReadiness(readiness(sensorIsFresh: false), .checkingDirection)
        assertReadiness(
            readiness(sensorIsFresh: false, preparationHasTimedOut: true),
            .directionDelayed
        )
        assertReadiness(readiness(), .ready)
    }

    private func readiness(
        location: DirectionReadiness.LocationState = .available,
        directionHardwareAvailable: Bool = true,
        sensorIsFresh: Bool = true,
        headingAccuracyDegrees: Double? = 4,
        targetAltitudeDegrees: Double? = 30,
        isMoving: Bool = false,
        preparationHasTimedOut: Bool = false,
        headingIsFresh: Bool = true
    ) -> DirectionReadiness {
        DirectionReadiness.evaluate(
            location: location,
            directionHardwareAvailable: directionHardwareAvailable,
            sensorIsFresh: sensorIsFresh,
            headingAccuracyDegrees: headingAccuracyDegrees,
            targetAltitudeDegrees: targetAltitudeDegrees,
            isMoving: isMoving,
            preparationHasTimedOut: preparationHasTimedOut,
            headingIsFresh: headingIsFresh
        )
    }

    private func assertReadiness(
        _ actual: DirectionReadiness,
        _ expected: DirectionReadiness,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        XCTAssertEqual(actual, expected, file: file, line: line)
        XCTAssertEqual(
            actual.canUseDirection,
            expected == .ready || expected == .approximate,
            file: file,
            line: line
        )
        XCTAssertEqual(actual.canConfirmAlignment, expected == .ready, file: file, line: line)
    }
}
