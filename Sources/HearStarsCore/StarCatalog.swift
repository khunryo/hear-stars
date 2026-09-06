import Foundation

public enum StarCatalog {
    /// Phase 1 is deliberately hand-curated. See docs/06-data-rights.md before
    /// changing values or adding catalogue rows.
    public static let prototype: [Star] = [
        Star(
            id: "polaris",
            nameKey: "star.polaris",
            designation: "α UMi",
            constellation: "UMi",
            j2000: .init(rightAscensionDegrees: 37.954_560_67, declinationDegrees: 89.264_108_97),
            properMotion: .init(rightAscensionMasPerYear: 44.48, declinationMasPerYear: -11.85),
            visualMagnitude: 1.98,
            discoveryPattern: .init(semitoneOffsets: [0, 7, 0], hapticDurations: [0.24, 0.09, 0.24])
        ),
        Star(
            id: "sirius",
            nameKey: "star.sirius",
            designation: "α CMa",
            constellation: "CMa",
            j2000: .init(rightAscensionDegrees: 101.287_155_33, declinationDegrees: -16.716_115_86),
            properMotion: .init(rightAscensionMasPerYear: -546.01, declinationMasPerYear: -1_223.07),
            visualMagnitude: -1.46,
            discoveryPattern: .init(semitoneOffsets: [0, 4, 12], hapticDurations: [0.08, 0.08, 0.24])
        ),
        Star(
            id: "vega",
            nameKey: "star.vega",
            designation: "α Lyr",
            constellation: "Lyr",
            j2000: .init(rightAscensionDegrees: 279.234_734_79, declinationDegrees: 38.783_688_96),
            properMotion: .init(rightAscensionMasPerYear: 200.94, declinationMasPerYear: 286.23),
            visualMagnitude: 0.03,
            discoveryPattern: .init(semitoneOffsets: [0, 9], hapticDurations: [0.22, 0.22])
        ),
        Star(
            id: "betelgeuse",
            nameKey: "star.betelgeuse",
            designation: "α Ori",
            constellation: "Ori",
            j2000: .init(rightAscensionDegrees: 88.792_938_99, declinationDegrees: 7.407_064_00),
            properMotion: .init(rightAscensionMasPerYear: 27.54, declinationMasPerYear: 10.86),
            visualMagnitude: 0.42,
            discoveryPattern: .init(semitoneOffsets: [0, -5, 3], hapticDurations: [0.08, 0.24, 0.08])
        ),
        Star(
            id: "rigel",
            nameKey: "star.rigel",
            designation: "β Ori",
            constellation: "Ori",
            j2000: .init(rightAscensionDegrees: 78.634_467_07, declinationDegrees: -8.201_638_37),
            properMotion: .init(rightAscensionMasPerYear: 1.87, declinationMasPerYear: -0.56),
            visualMagnitude: 0.13,
            discoveryPattern: .init(semitoneOffsets: [0, 5, 10], hapticDurations: [0.15, 0.15, 0.15])
        )
    ]
}
