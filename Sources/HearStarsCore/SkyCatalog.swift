import Foundation

public struct SkyConstellation: Identifiable, Sendable {
    public let id: String
    public let nameKey: String
    public let starIDs: [String]
    public let links: [(String, String)]
}

/// Small manually selected J2000 table, not copied chart artwork.
/// IAU WGSN / IAU Catalog of Star Names, accessed 2026-10-11:
/// https://iauarchive.eso.org/public/themes/naming_stars/
/// Gamma Cas: Wikidata Q13584, P6257/P6258 (CC0).
/// See docs/11-sky-data.md for provenance, approximations and release gate.
public enum SkyCatalog {
    public static let stars: [Star] = StarCatalog.prototype + [
        star("kochab", "UMi", 222.676357, 74.155504, 2.07),
        star("pherkad", "UMi", 230.182150, 71.834017, 3.00),
        star("yildun", "UMi", 263.054126, 86.586462, 4.35),
        star("dubhe", "UMa", 165.931965, 61.751035, 1.81),
        star("merak", "UMa", 165.460319, 56.382426, 2.34),
        star("phecda", "UMa", 178.457679, 53.694758, 2.41),
        star("megrez", "UMa", 183.856503, 57.032615, 3.32),
        star("alioth", "UMa", 193.507290, 55.959823, 1.76),
        star("mizar", "UMa", 200.981429, 54.925362, 2.23),
        star("alkaid", "UMa", 206.885157, 49.313267, 1.85),
        star("caph", "Cas", 2.294522, 59.149781, 2.28),
        star("schedar", "Cas", 10.126838, 56.537331, 2.24),
        star("gammacas", "Cas", 14.17721289375, 60.71674002472, 2.2),
        star("ruchbah", "Cas", 21.453964, 60.235284, 2.66),
        star("segin", "Cas", 28.598857, 63.670101, 3.35),
        star("sheliak", "Lyr", 282.519978, 33.362668, 3.52),
        star("sulafat", "Lyr", 284.735928, 32.689557, 3.25),
        star("bellatrix", "Ori", 81.282764, 6.349703, 1.64),
        star("saiph", "Ori", 86.939120, -9.669605, 2.07),
        star("alnitak", "Ori", 85.189694, -1.942574, 1.74),
        star("alnilam", "Ori", 84.053389, -1.201919, 1.69),
        star("mintaka", "Ori", 83.001667, -0.299095, 2.25),
        star("mirzam", "CMa", 95.674939, -17.955919, 1.98),
        star("wezen", "CMa", 107.097850, -26.393200, 1.83),
        star("adhara", "CMa", 104.656453, -28.972086, 1.50),
        star("aludra", "CMa", 111.023760, -29.303106, 2.45)
    ]

    public static let constellations: [SkyConstellation] = [
        group("umi", ["polaris", "yildun", "kochab", "pherkad"],
              [("polaris", "yildun"), ("yildun", "pherkad"), ("pherkad", "kochab")]),
        group("uma", ["dubhe", "merak", "phecda", "megrez", "alioth", "mizar", "alkaid"],
              [("dubhe", "merak"), ("merak", "phecda"), ("phecda", "megrez"),
               ("megrez", "dubhe"), ("megrez", "alioth"), ("alioth", "mizar"), ("mizar", "alkaid")]),
        group("cas", ["caph", "schedar", "gammacas", "ruchbah", "segin"],
              [("caph", "schedar"), ("schedar", "gammacas"), ("gammacas", "ruchbah"), ("ruchbah", "segin")]),
        group("lyr", ["vega", "sheliak", "sulafat"],
              [("vega", "sheliak"), ("sheliak", "sulafat")]),
        group("ori", ["betelgeuse", "bellatrix", "alnitak", "alnilam", "mintaka", "saiph", "rigel"],
              [("betelgeuse", "bellatrix"), ("betelgeuse", "alnitak"),
               ("bellatrix", "mintaka"), ("alnitak", "alnilam"), ("alnilam", "mintaka"),
               ("alnitak", "saiph"), ("mintaka", "rigel"), ("rigel", "saiph")]),
        group("cma", ["sirius", "mirzam", "wezen", "adhara", "aludra"],
              [("mirzam", "sirius"), ("sirius", "wezen"), ("wezen", "adhara"), ("wezen", "aludra")])
    ]

    public static func constellation(for starID: String) -> SkyConstellation? {
        constellations.first { $0.starIDs.contains(starID) }
    }

    /// Suggest only visible, reasonably bright stars; never auto-select one.
    public static func nextStar(after selectedID: String, observations: [String: HorizontalCoordinate]) -> Star? {
        guard let origin = observations[selectedID] else { return nil }
        let members = Set(constellation(for: selectedID)?.starIDs ?? [])
        return stars.filter {
            $0.id != selectedID && $0.visualMagnitude <= 3.6 && (observations[$0.id]?.altitudeDegrees ?? -90) >= 5
        }.min { lhs, rhs in
            let lMember = members.contains(lhs.id), rMember = members.contains(rhs.id)
            if lMember != rMember { return lMember }
            let l = SkyVector(origin).dot(SkyVector(observations[lhs.id]!))
            let r = SkyVector(origin).dot(SkyVector(observations[rhs.id]!))
            return l > r
        }
    }

    private static func star(_ id: String, _ constellation: String, _ ra: Double, _ dec: Double, _ magnitude: Double) -> Star {
        .init(id: id, nameKey: "skyStar." + id, designation: id == "gammacas" ? "γ Cas" : id.capitalized,
            constellation: constellation, j2000: .init(rightAscensionDegrees: ra, declinationDegrees: dec),
            properMotion: .init(rightAscensionMasPerYear: 0, declinationMasPerYear: 0), visualMagnitude: magnitude,
            discoveryPattern: .init(semitoneOffsets: [0, 7], hapticDurations: [0.12, 0.24]))
    }
    private static func group(_ id: String, _ stars: [String], _ links: [(String, String)]) -> SkyConstellation {
        .init(id: id, nameKey: "constellation." + id, starIDs: stars, links: links)
    }
}
