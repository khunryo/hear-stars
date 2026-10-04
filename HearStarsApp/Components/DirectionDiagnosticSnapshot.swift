import Foundation
import HearStarsCore

/// Immutable inputs captured together; no coordinates, disk storage, or networking.
struct DirectionSensorSnapshot: Equatable {
    let uptime: TimeInterval
    let motionAge: TimeInterval?
    let headingAge: TimeInterval?
    let aim: DeviceAim?
    let isMoving: Bool
    let rawAccuracy: Double?
    let residual: Double?
    let gravityError: Double?
    let reference: HeadingReference
    let hasTrueHeading: Bool
    let magneticKey: String
    let magneticCalibrated: Bool

    var motionIsFresh: Bool {
        guard let motionAge else { return false }
        return motionAge.isFinite && motionAge >= 0 && motionAge <= 0.25
    }
    var headingIsFresh: Bool {
        guard let headingAge else { return false }
        return headingAge.isFinite && headingAge >= 0 && headingAge <= 2
    }
    var assessment: HeadingAssessment {
        HeadingAssessment.evaluate(
            headingAccuracyDegrees: rawAccuracy, headingIsFresh: headingIsFresh,
            reference: reference, hasTrueHeading: hasTrueHeading,
            residualDegrees: residual, gravityErrorDegrees: gravityError,
            magneticCalibrated: magneticCalibrated
        )
    }
}

struct DirectionDiagnosticSnapshot: Equatable {
    let state: DirectionReadiness
    let sensors: DirectionSensorSnapshot

    var copyPrefix: String? {
        guard state == .calibrating || state == .checkingDirection || state == .directionDelayed else { return nil }
        if !sensors.motionIsFresh || sensors.aim == nil { return "sensorIssue.motionWaiting" }
        return sensors.assessment.issue.map { "sensorIssue." + $0.rawValue }
    }
    var reasonKey: String { copyPrefix.map { $0 + ".title" } ?? state.titleLocalizationKey }

    func summary(bundle: Bundle = .main) -> String {
        func number(_ value: Double?) -> String {
            guard let value, value.isFinite else { return "—" }
            return String(format: "%.2f", locale: .current, value)
        }
        let yesNo = sensors.hasTrueHeading ? "diagnostics.yes" : "diagnostics.no"
        let format = L10n.string("diagnostics.snapshot", bundle: bundle)
        return String(format: format, locale: .current,
            L10n.string(reasonKey, bundle: bundle), number(sensors.rawAccuracy),
            number(sensors.assessment.effectiveAccuracyDegrees), number(sensors.headingAge),
            number(sensors.motionAge), L10n.string("diagnostics.reference." + sensors.reference.rawValue, bundle: bundle),
            L10n.string(yesNo, bundle: bundle), number(sensors.residual), number(sensors.gravityError),
            L10n.string(sensors.magneticKey, bundle: bundle))
    }
}

/// In-memory transition history for the troubleshooting disclosure. It keeps
/// only the current reading and the precise reading that stopped guidance.
struct DirectionDiagnosticHistory {
    private(set) var current: DirectionDiagnosticSnapshot? = nil
    private(set) var lastStop: DirectionDiagnosticSnapshot? = nil

    mutating func record(_ diagnostic: DirectionDiagnosticSnapshot) {
        let wasGuiding = current?.state.canUseDirection == true
        current = diagnostic
        if wasGuiding && !diagnostic.state.canUseDirection {
            lastStop = diagnostic
        }
    }

    mutating func clear() {
        current = nil
        lastStop = nil
    }
}
