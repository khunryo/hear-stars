import Foundation

public struct EquatorialCoordinate: Equatable, Sendable {
    public let rightAscensionDegrees: Double
    public let declinationDegrees: Double

    public init(rightAscensionDegrees: Double, declinationDegrees: Double) {
        self.rightAscensionDegrees = AngleMath.normalizeDegrees(rightAscensionDegrees)
        self.declinationDegrees = AngleMath.clamp(declinationDegrees, min: -90.0, max: 90.0)
    }
}

public struct ProperMotion: Equatable, Sendable {
    /// μ_α* = dα/dt × cos(δ), in milliarcseconds per Julian year.
    public let rightAscensionMasPerYear: Double
    public let declinationMasPerYear: Double

    public init(rightAscensionMasPerYear: Double, declinationMasPerYear: Double) {
        self.rightAscensionMasPerYear = rightAscensionMasPerYear
        self.declinationMasPerYear = declinationMasPerYear
    }
}

public struct Star: Identifiable, Equatable, Sendable {
    public let id: String
    public let nameKey: String
    public let designation: String
    public let constellation: String
    public let j2000: EquatorialCoordinate
    public let properMotion: ProperMotion
    public let visualMagnitude: Double
    public let discoveryPattern: DiscoveryPattern

    public init(
        id: String,
        nameKey: String,
        designation: String,
        constellation: String,
        j2000: EquatorialCoordinate,
        properMotion: ProperMotion,
        visualMagnitude: Double,
        discoveryPattern: DiscoveryPattern
    ) {
        self.id = id
        self.nameKey = nameKey
        self.designation = designation
        self.constellation = constellation
        self.j2000 = j2000
        self.properMotion = properMotion
        self.visualMagnitude = visualMagnitude
        self.discoveryPattern = discoveryPattern
    }
}

public struct DiscoveryPattern: Equatable, Sendable {
    /// Original semitone offsets used by the synthesizer.
    public let semitoneOffsets: [Int]
    /// Original long/short rhythm, expressed in seconds.
    public let hapticDurations: [Double]

    public init(semitoneOffsets: [Int], hapticDurations: [Double]) {
        self.semitoneOffsets = semitoneOffsets
        self.hapticDurations = hapticDurations
    }
}
