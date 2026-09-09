import Foundation

public struct DeviceAim: Equatable, Sendable {
    public let azimuthDegrees: Double
    public let altitudeDegrees: Double

    public init(azimuthDegrees: Double, altitudeDegrees: Double) {
        self.azimuthDegrees = AngleMath.normalizeDegrees(azimuthDegrees)
        self.altitudeDegrees = AngleMath.clamp(altitudeDegrees, min: -90.0, max: 90.0)
    }
}

public enum GuidanceBand: String, Equatable, Sendable {
    case far
    case broad
    case near
    case close
    case aligned
}

public enum DirectionCue: String, Equatable, Sendable {
    case aligned
    case vicinity
    case reverse
    case left
    case right
    case up
    case down
    case upLeft
    case upRight
    case downLeft
    case downRight
}

public enum HeadingQuality: String, Equatable, Sendable {
    case unavailable
    case approximate
    case fair
    case good
}

public struct GuidanceInput: Equatable, Sendable {
    public let target: HorizontalCoordinate
    public let aim: DeviceAim
    public let headingAccuracyDegrees: Double?
    public let isMoving: Bool
    public let isSensorFresh: Bool
    public let isPractice: Bool

    public init(
        target: HorizontalCoordinate,
        aim: DeviceAim,
        headingAccuracyDegrees: Double?,
        isMoving: Bool,
        isSensorFresh: Bool,
        isPractice: Bool
    ) {
        self.target = target
        self.aim = aim
        self.headingAccuracyDegrees = headingAccuracyDegrees
        self.isMoving = isMoving
        self.isSensorFresh = isSensorFresh
        self.isPractice = isPractice
    }
}

public struct GuidanceState: Equatable, Sendable {
    public let azimuthErrorDegrees: Double
    public let altitudeErrorDegrees: Double
    public let angularSeparationDegrees: Double
    public let direction: DirectionCue
    public let band: GuidanceBand
    public let headingQuality: HeadingQuality
    public let pulseIntervalSeconds: Double
    public let clarity: Double
    public let discoveryToleranceDegrees: Double
    public let canGuide: Bool
    public let canDiscover: Bool
}

public enum GuidanceMapper {
    public static func map(_ input: GuidanceInput) -> GuidanceState {
        let azimuthError = AngleMath.signedDegrees(
            input.target.azimuthDegrees - input.aim.azimuthDegrees
        )
        let altitudeError = input.target.altitudeDegrees - input.aim.altitudeDegrees
        let separation = angularSeparation(
            azimuthA: input.target.azimuthDegrees,
            altitudeA: input.target.altitudeDegrees,
            azimuthB: input.aim.azimuthDegrees,
            altitudeB: input.aim.altitudeDegrees
        )
        let quality = headingQuality(input.headingAccuracyDegrees)
        let tolerance = discoveryTolerance(input.headingAccuracyDegrees)
        let band = guidanceBand(
            separation: separation,
            tolerance: tolerance,
            quality: quality
        )
        let canGuide = input.isSensorFresh
            && !input.isMoving
            && quality != .unavailable
        let canDiscover = canGuide
            && (input.isPractice || input.target.altitudeDegrees >= 2.0)
            && quality != .unavailable
            && quality != .approximate
            && separation <= tolerance

        return GuidanceState(
            azimuthErrorDegrees: azimuthError,
            altitudeErrorDegrees: altitudeError,
            angularSeparationDegrees: separation,
            direction: directionCue(
                angularSeparation: separation,
                azimuthError: azimuthError,
                altitudeError: altitudeError,
                tolerance: tolerance,
                quality: quality,
                accuracy: input.headingAccuracyDegrees
            ),
            band: band,
            headingQuality: quality,
            pulseIntervalSeconds: pulseInterval(for: band),
            clarity: min(
                AngleMath.clamp(1.0 - separation / 55.0, min: 0.0, max: 1.0),
                quality == .approximate ? 0.6 : 1.0
            ),
            discoveryToleranceDegrees: tolerance,
            canGuide: canGuide,
            canDiscover: canDiscover
        )
    }

    public static func angularSeparation(
        azimuthA: Double,
        altitudeA: Double,
        azimuthB: Double,
        altitudeB: Double
    ) -> Double {
        let azA = AngleMath.radians(azimuthA)
        let altA = AngleMath.radians(altitudeA)
        let azB = AngleMath.radians(azimuthB)
        let altB = AngleMath.radians(altitudeB)
        let a = horizontalUnitVector(azimuth: azA, altitude: altA)
        let b = horizontalUnitVector(azimuth: azB, altitude: altB)
        let dot = a.x * b.x + a.y * b.y + a.z * b.z
        let crossX = a.y * b.z - a.z * b.y
        let crossY = a.z * b.x - a.x * b.z
        let crossZ = a.x * b.y - a.y * b.x
        let crossLength = sqrt(crossX * crossX + crossY * crossY + crossZ * crossZ)
        return AngleMath.degrees(atan2(crossLength, dot))
    }

    private static func horizontalUnitVector(
        azimuth: Double,
        altitude: Double
    ) -> (x: Double, y: Double, z: Double) {
        // East, North, Up.
        (
            x: cos(altitude) * sin(azimuth),
            y: cos(altitude) * cos(azimuth),
            z: sin(altitude)
        )
    }

    public static func headingQuality(_ accuracy: Double?) -> HeadingQuality {
        guard let accuracy, accuracy.isFinite, accuracy >= 0, accuracy <= 25.0 else { return .unavailable }
        if accuracy <= 8.0 { return .good }
        if accuracy <= 10.0 { return .fair }
        return .approximate
    }

    private static func discoveryTolerance(_ accuracy: Double?) -> Double {
        guard let accuracy, accuracy >= 0 else { return 3.0 }
        return AngleMath.clamp(3.0 + accuracy / 3.0, min: 3.0, max: 6.0)
    }

    private static func guidanceBand(
        separation: Double,
        tolerance: Double,
        quality: HeadingQuality
    ) -> GuidanceBand {
        let band: GuidanceBand
        if separation <= tolerance { band = .aligned }
        else if separation <= 8.0 { band = .close }
        else if separation <= 20.0 { band = .near }
        else if separation <= 45.0 { band = .broad }
        else { band = .far }
        if quality == .approximate, band == .aligned || band == .close { return .near }
        return band
    }

    private static func pulseInterval(for band: GuidanceBand) -> Double {
        switch band {
        case .far: return 1.50
        case .broad: return 0.90
        case .near: return 0.45
        case .close: return 0.22
        case .aligned: return 0.12
        }
    }

    private static func directionCue(
        angularSeparation: Double,
        azimuthError: Double,
        altitudeError: Double,
        tolerance: Double,
        quality: HeadingQuality,
        accuracy: Double?
    ) -> DirectionCue {
        if quality == .approximate,
           let accuracy,
           accuracy.isFinite,
           angularSeparation <= max(accuracy, tolerance) {
            return .vicinity
        }
        if angularSeparation <= tolerance { return .aligned }
        if abs(azimuthError) >= 135.0 { return .reverse }

        let horizontal = abs(azimuthError) > max(4.0, tolerance)
        let vertical = abs(altitudeError) > max(4.0, tolerance)

        switch (horizontal, vertical, azimuthError >= 0, altitudeError >= 0) {
        case (true, true, true, true): return .upRight
        case (true, true, false, true): return .upLeft
        case (true, true, true, false): return .downRight
        case (true, true, false, false): return .downLeft
        case (true, false, true, _): return .right
        case (true, false, false, _): return .left
        case (false, true, _, true): return .up
        case (false, true, _, false): return .down
        default:
            // The great-circle distance can exceed the discovery tolerance
            // even when neither component crosses its wording threshold. Do
            // not call that state aligned; give the dominant correction.
            if abs(altitudeError) >= abs(azimuthError) {
                return altitudeError >= 0 ? .up : .down
            }
            return azimuthError >= 0 ? .right : .left
        }
    }
}
