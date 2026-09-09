import Foundation

/// Readiness is based on live measurements, never on an elapsed calibration animation.
public enum DirectionReadiness: String, CaseIterable, Equatable, Sendable {
    case locationPermission, locationDenied, locationRestricted, locationServicesOff
    case locating, locationDelayed, sensorUnavailable, checkingDirection, directionDelayed
    case calibrating, approximate, moving, belowHorizon, ready

    public var canUseDirection: Bool { self == .ready || self == .approximate }
    public var canConfirmAlignment: Bool { self == .ready }

    // Assemble a plain String before handing the key to a localization API.
    public var titleLocalizationKey: String { "readiness." + rawValue + ".title" }
    public var bodyLocalizationKey: String { "readiness." + rawValue + ".body" }

    public enum LocationState: Sendable {
        case permissionRequired, denied, restricted, servicesOff, waiting, available
    }

    public static func evaluate(
        location: LocationState,
        directionHardwareAvailable: Bool,
        sensorIsFresh: Bool,
        headingAccuracyDegrees: Double?,
        targetAltitudeDegrees: Double?,
        isMoving: Bool,
        preparationHasTimedOut: Bool,
        headingIsFresh: Bool = true
    ) -> Self {
        switch location {
        case .permissionRequired: return .locationPermission
        case .denied: return .locationDenied
        case .restricted: return .locationRestricted
        case .servicesOff: return .locationServicesOff
        case .waiting: return preparationHasTimedOut ? .locationDelayed : .locating
        case .available: break
        }
        guard directionHardwareAvailable else { return .sensorUnavailable }
        guard let altitude = targetAltitudeDegrees else {
            return preparationHasTimedOut ? .locationDelayed : .locating
        }
        guard altitude >= 2 else { return .belowHorizon }
        guard !isMoving else { return .moving }
        // A missing change-driven compass update is not evidence of magnetic
        // calibration failure. Pause honestly as data waiting, not "figure eight".
        guard sensorIsFresh && headingIsFresh else {
            return preparationHasTimedOut ? .directionDelayed : .checkingDirection
        }
        switch GuidanceMapper.headingQuality(headingAccuracyDegrees) {
        case .good, .fair: return .ready
        case .approximate: return .approximate
        case .unavailable: return .calibrating
        }
    }
}
