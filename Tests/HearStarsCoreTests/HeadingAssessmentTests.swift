import XCTest
@testable import HearStarsCore

final class HeadingAssessmentTests: XCTestCase {
    func testHealthyAccuracyValuesRemainUsable() {
        for accuracy in [14.5, 25, 10, 0.9, 0] {
            XCTAssertEqual(assessment(accuracy).effectiveAccuracyDegrees, accuracy)
            XCTAssertNil(assessment(accuracy).issue)
        }
    }

    func testResidualMakesAccuracyConservative() {
        let value = assessment(14.5, residual: 20)
        XCTAssertEqual(value.effectiveAccuracyDegrees, 20)
        XCTAssertNil(value.issue)
    }

    func testHighRawAccuracyIsUncertainOnlyAboveBoundary() {
        XCTAssertNil(assessment(25).issue)
        XCTAssertEqual(assessment(25.000_001), .init(effectiveAccuracyDegrees: 25.000_001, issue: .headingUncertain))
    }

    func testStaleHeadingWinsOverOtherFailures() {
        XCTAssertEqual(
            assessment(nil, fresh: false, reference: .arbitrary, calibrated: false),
            .init(effectiveAccuracyDegrees: nil, issue: .headingWaiting)
        )
    }

    func testInvalidRawValuesAreUnavailable() {
        for value: Double? in [nil, -0.1, .nan, .infinity, -.infinity] {
            XCTAssertEqual(assessment(value), .init(effectiveAccuracyDegrees: nil, issue: .headingUnavailable))
        }
    }

    func testArbitraryReferenceHasNoNorth() {
        XCTAssertEqual(assessment(4, reference: .arbitrary), .init(effectiveAccuracyDegrees: nil, issue: .northUnavailable))
    }

    func testMagneticReferenceRequiresTrueHeading() {
        XCTAssertEqual(assessment(4, reference: .magnetic, hasTrueHeading: false), .init(effectiveAccuracyDegrees: nil, issue: .northUnavailable))
        XCTAssertNil(assessment(4, reference: .magnetic, hasTrueHeading: true).issue)
    }

    func testUncalibratedMagneticFieldIsAtLeastThirtyDegrees() {
        XCTAssertEqual(assessment(14.5, calibrated: false), .init(effectiveAccuracyDegrees: 30, issue: .magneticUncalibrated))
        XCTAssertEqual(assessment(32, calibrated: false), .init(effectiveAccuracyDegrees: 32, issue: .magneticUncalibrated))
        XCTAssertEqual(assessment(14.5, residual: 60, calibrated: false), .init(effectiveAccuracyDegrees: 60, issue: .magneticUncalibrated))
    }

    func testGravityBoundaryAndMismatch() {
        XCTAssertNil(assessment(14.5, gravity: 2).issue)
        XCTAssertEqual(assessment(14.5, gravity: 2.000_001), .init(effectiveAccuracyDegrees: 30, issue: .gravityMismatch))
        XCTAssertEqual(assessment(14.5, residual: 60, gravity: 2.000_001), .init(effectiveAccuracyDegrees: 60, issue: .gravityMismatch))
    }

    func testExcessiveResidualIsSensorDisagreement() {
        XCTAssertEqual(assessment(14.5, residual: 25.000_001), .init(effectiveAccuracyDegrees: 25.000_001, issue: .sensorDisagreement))
    }

    func testNonfiniteResidualAndGravityFailClosed() {
        XCTAssertEqual(assessment(4, residual: .nan), .init(effectiveAccuracyDegrees: nil, issue: .sensorDisagreement))
        XCTAssertEqual(assessment(4, gravity: .infinity), .init(effectiveAccuracyDegrees: nil, issue: .gravityMismatch))
        XCTAssertEqual(assessment(4, residual: -0.1), .init(effectiveAccuracyDegrees: nil, issue: .sensorDisagreement))
        XCTAssertEqual(assessment(4, gravity: -0.1), .init(effectiveAccuracyDegrees: nil, issue: .gravityMismatch))
    }

    func testSystemCalibrationPromptBoundaries() {
        for accuracy: Double? in [0, 0.9, 25] {
            XCTAssertFalse(HeadingAssessment.shouldDisplaySystemCalibration(headingAccuracyDegrees: accuracy, isRunning: true))
        }
        for accuracy: Double? in [nil, -0.1, .nan, .infinity, 25.000_001] {
            XCTAssertTrue(HeadingAssessment.shouldDisplaySystemCalibration(headingAccuracyDegrees: accuracy, isRunning: true))
        }
        XCTAssertFalse(HeadingAssessment.shouldDisplaySystemCalibration(headingAccuracyDegrees: nil, isRunning: false))
        XCTAssertFalse(HeadingAssessment.shouldDisplaySystemCalibration(headingAccuracyDegrees: 30, isRunning: false))
    }

    private func assessment(
        _ accuracy: Double?,
        fresh: Bool = true,
        reference: HeadingReference = .trueNorth,
        hasTrueHeading: Bool = true,
        residual: Double? = nil,
        gravity: Double? = nil,
        calibrated: Bool = true
    ) -> HeadingAssessment {
        HeadingAssessment.evaluate(
            headingAccuracyDegrees: accuracy,
            headingIsFresh: fresh,
            reference: reference,
            hasTrueHeading: hasTrueHeading,
            residualDegrees: residual,
            gravityErrorDegrees: gravity,
            magneticCalibrated: calibrated
        )
    }
}
