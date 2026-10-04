import Foundation

public enum HeadingReference: String, Equatable, Sendable {
    case trueNorth
    case magnetic
    case arbitrary
}

public enum HeadingIssue: String, CaseIterable, Equatable, Sendable {
    case headingWaiting
    case headingUnavailable
    case northUnavailable
    case magneticUncalibrated
    case gravityMismatch
    case sensorDisagreement
    case headingUncertain
}

/// A platform-independent assessment of whether a compass sample is safe to use.
public struct HeadingAssessment: Equatable, Sendable {
    public let effectiveAccuracyDegrees: Double?
    public let issue: HeadingIssue?

    public static func evaluate(
        headingAccuracyDegrees: Double?,
        headingIsFresh: Bool,
        reference: HeadingReference,
        hasTrueHeading: Bool,
        residualDegrees: Double?,
        gravityErrorDegrees: Double?,
        magneticCalibrated: Bool
    ) -> Self {
        guard headingIsFresh else {
            return unavailable(.headingWaiting)
        }

        guard let headingAccuracyDegrees,
              headingAccuracyDegrees.isFinite,
              headingAccuracyDegrees >= 0 else {
            return unavailable(.headingUnavailable)
        }

        guard reference != .arbitrary,
              reference != .magnetic || hasTrueHeading else {
            return unavailable(.northUnavailable)
        }

        let invalidResidual = residualDegrees.map { !$0.isFinite || $0 < 0 } ?? false
        let invalidGravity = gravityErrorDegrees.map { !$0.isFinite || $0 < 0 } ?? false
        let conservativeAccuracyDegrees = max(
            headingAccuracyDegrees,
            invalidResidual ? headingAccuracyDegrees : (residualDegrees ?? headingAccuracyDegrees)
        )

        guard magneticCalibrated else {
            return .init(
                effectiveAccuracyDegrees: invalidResidual || invalidGravity
                    ? nil
                    : max(conservativeAccuracyDegrees, 30),
                issue: .magneticUncalibrated
            )
        }

        if let gravityErrorDegrees {
            guard !invalidGravity else {
                return unavailable(.gravityMismatch)
            }
            if gravityErrorDegrees > 2 {
                return .init(
                    effectiveAccuracyDegrees: invalidResidual
                        ? nil
                        : max(conservativeAccuracyDegrees, 30),
                    issue: .gravityMismatch
                )
            }
        }

        if let residualDegrees {
            guard !invalidResidual else {
                return unavailable(.sensorDisagreement)
            }
            if residualDegrees > 25 {
                return .init(
                    effectiveAccuracyDegrees: conservativeAccuracyDegrees,
                    issue: .sensorDisagreement
                )
            }
            if headingAccuracyDegrees > 25 {
                return .init(
                    effectiveAccuracyDegrees: conservativeAccuracyDegrees,
                    issue: .headingUncertain
                )
            }
            return .init(effectiveAccuracyDegrees: conservativeAccuracyDegrees, issue: nil)
        }

        return .init(
            effectiveAccuracyDegrees: headingAccuracyDegrees,
            issue: headingAccuracyDegrees > 25 ? .headingUncertain : nil
        )
    }

    /// Mirrors the coarse system calibration prompt threshold without requiring motion.
    public static func shouldDisplaySystemCalibration(
        headingAccuracyDegrees: Double?,
        isRunning: Bool
    ) -> Bool {
        guard isRunning else { return false }
        guard let headingAccuracyDegrees,
              headingAccuracyDegrees.isFinite,
              headingAccuracyDegrees >= 0 else {
            return true
        }
        return headingAccuracyDegrees > 25
    }

    private static func unavailable(_ issue: HeadingIssue) -> Self {
        .init(effectiveAccuracyDegrees: nil, issue: issue)
    }
}
