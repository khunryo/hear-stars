import Foundation

/// Full sky positions: Yale BSC5, Hoffleit & Warren (1991), Bretton Wade's MIT export.
/// Lines: d3-celestial / Olaf Frohn (BSD-3-Clause), adapted to Yale endpoints.
/// See bundled SkyDataNotices.txt and docs/14-full-sky-data.md; no runtime download.
public enum SkyCatalog {
    private static let expanded = try? FullSkyCatalog.load()
    public static var catalogIsExpanded: Bool { expanded != nil }
    public static var noticesURL: URL? { FullSkyCatalog.bundle.url(forResource: "SkyDataNotices", withExtension: "txt") }
    public static let constellations: [SkyConstellation] = expanded?.constellations.map {
        SkyConstellation(id: $0.id, nameKey: "constellation." + $0.id, starIDs: $0.starIDs,
                         links: $0.links.map { ($0[0], $0[1]) })
    } ?? LegacySkyCatalog.constellations
    public static let stars: [Star] = {
        guard let expanded else { return LegacySkyCatalog.stars }
        let originals = Dictionary(uniqueKeysWithValues: LegacySkyCatalog.stars.map { ($0.id, $0) })
        var memberships: [String: String] = [:]
        for figure in constellations {
            for id in figure.starIDs where memberships[id] == nil { memberships[id] = figure.id }
        }
        return expanded.stars.map { row in
            originals[row.id] ?? Star(id: row.id, nameKey: row.designation, designation: row.designation,
                constellation: memberships[row.id] ?? "", j2000: .init(rightAscensionDegrees: row.ra, declinationDegrees: row.dec),
                properMotion: .init(rightAscensionMasPerYear: 0, declinationMasPerYear: 0), visualMagnitude: row.mag,
                discoveryPattern: .init(semitoneOffsets: [0, 7], hapticDurations: [0.12, 0.24]))
        }
    }()
    public static let starsByID = Dictionary(uniqueKeysWithValues: stars.map { ($0.id, $0) })
    public static let starsByBrightness = stars.sorted { $0.visualMagnitude < $1.visualMagnitude }
    private static let memberships: [String: SkyConstellation] = {
        var result: [String: SkyConstellation] = [:]
        for figure in constellations {
            for id in figure.starIDs where result[id] == nil { result[id] = figure }
        }
        return result
    }()
    public static func constellation(for starID: String) -> SkyConstellation? { memberships[starID] }
    public static func anchor(for constellationID: String, observations: [String: HorizontalCoordinate]) -> Star? {
        guard let group = constellations.first(where: { $0.id == constellationID }) else { return nil }
        return group.starIDs.compactMap { starsByID[$0] }.filter {
            (observations[$0.id]?.altitudeDegrees ?? -90) >= 5
        }.min { $0.visualMagnitude < $1.visualMagnitude }
    }
    public static func nextStar(after selectedID: String, observations: [String: HorizontalCoordinate]) -> Star? {
        guard let origin = observations[selectedID] else { return nil }
        let members = Set(constellation(for: selectedID)?.starIDs ?? [])
        let candidates = starsByBrightness.filter {
            $0.id != selectedID && $0.visualMagnitude <= 3.6
                && (observations[$0.id]?.altitudeDegrees ?? -90) >= 5
        }
        return candidates.min { lhs, rhs in
            let lMember = members.contains(lhs.id), rMember = members.contains(rhs.id)
            if lMember != rMember { return lMember }
            guard let l = observations[lhs.id], let r = observations[rhs.id] else { return false }
            return SkyVector(origin).dot(SkyVector(l)) > SkyVector(origin).dot(SkyVector(r))
        }
    }
}
