import XCTest
@testable import HearStarsCore

final class DirectionReadinessTests: XCTestCase {
    func testCalibrationBecomesReadyWhenLiveHeadingImprovesToGoodOrFair() {
        assertReadiness(readiness(headingAccuracyDegrees: nil), .calibrating)
        assertReadiness(readiness(headingAccuracyDegrees: 18), .calibrating)
        assertReadiness(readiness(headingAccuracyDegrees: 8), .ready)
        assertReadiness(readiness(headingAccuracyDegrees: 10), .ready)
    }

    func testElapsedPreparationNeverMakesBadOrMissingHeadingReady() {
        let unusableAccuracies: [Double?] = [nil, -1, 10.001, 25, 25.001, Double.nan, Double.infinity]
        for accuracy in unusableAccuracies {
            for timedOut in [false, true] {
                assertReadiness(
                    readiness(headingAccuracyDegrees: accuracy, preparationHasTimedOut: timedOut),
                    .calibrating
                )
            }
        }
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
        assertReadiness(readiness(headingAccuracyDegrees: 12), .calibrating)
        assertReadiness(readiness(headingAccuracyDegrees: nil), .calibrating)
        assertReadiness(readiness(headingAccuracyDegrees: 9), .ready)
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
        preparationHasTimedOut: Bool = false
    ) -> DirectionReadiness {
        DirectionReadiness.evaluate(
            location: location,
            directionHardwareAvailable: directionHardwareAvailable,
            sensorIsFresh: sensorIsFresh,
            headingAccuracyDegrees: headingAccuracyDegrees,
            targetAltitudeDegrees: targetAltitudeDegrees,
            isMoving: isMoving,
            preparationHasTimedOut: preparationHasTimedOut
        )
    }

    private func assertReadiness(
        _ actual: DirectionReadiness,
        _ expected: DirectionReadiness,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        XCTAssertEqual(actual, expected, file: file, line: line)
        XCTAssertEqual(actual.canUseDirection, expected == .ready, file: file, line: line)
    }
}
