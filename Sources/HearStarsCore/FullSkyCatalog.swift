import Foundation

struct FullSkyCatalog: Decodable {
    struct Row: Decodable {
        let id: String
        let ra: Double
        let dec: Double
        let mag: Double
        let designation: String
    }
    struct Figure: Decodable {
        let id: String
        let starIDs: [String]
        let links: [[String]]
    }
    let schema: Int
    let stars: [Row]
    let constellations: [Figure]

    static var bundle: Bundle {
        #if SWIFT_PACKAGE
        return Bundle.module
        #else
        return Bundle(for: SkyResourceBundleMarker.self)
        #endif
    }
    static func load() throws -> Self {
        guard let url = bundle.url(forResource: "full-sky", withExtension: "json") else {
            throw CocoaError(.fileNoSuchFile)
        }
        let catalog = try JSONDecoder().decode(Self.self, from: Data(contentsOf: url))
        let starIDs = Set(catalog.stars.map(\.id))
        guard catalog.schema == 1, catalog.constellations.count == 88,
              starIDs.count == catalog.stars.count,
              Set(catalog.constellations.map(\.id)).count == 88,
              catalog.stars.allSatisfy({ $0.ra.isFinite && $0.dec.isFinite && $0.mag.isFinite
                  && (0..<360).contains($0.ra) && (-90...90).contains($0.dec) }),
              catalog.constellations.allSatisfy({ figure in
                  !figure.links.isEmpty && Set(figure.starIDs).isSubset(of: starIDs)
                      && figure.links.allSatisfy { $0.count == 2 && $0[0] != $0[1]
                          && figure.starIDs.contains($0[0]) && figure.starIDs.contains($0[1]) }
              }) else { throw CocoaError(.fileReadCorruptFile) }
        return catalog
    }
}
private final class SkyResourceBundleMarker: NSObject {}
