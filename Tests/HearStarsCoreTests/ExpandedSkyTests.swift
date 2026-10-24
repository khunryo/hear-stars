import XCTest
@testable import HearStarsCore

final class ExpandedSkyTests: XCTestCase {
    func testWholeSkyIncludesAllEightyEightConstellations() {
        XCTAssertEqual(Set(SkyCatalog.constellations.map(\.id)).count, 88)
        for id in ["and", "tau", "leo", "cyg", "sco", "cru", "ser", "men"] {
            XCTAssertTrue(SkyCatalog.constellations.contains { $0.id == id }, "Missing \(id)")
        }
    }
    func testManyRealStarsAndNoDuplicateOriginalIdentities() {
        XCTAssertGreaterThanOrEqual(SkyCatalog.stars.count, 5_000)
        XCTAssertEqual(Set(SkyCatalog.stars.map(\.id)).count, SkyCatalog.stars.count)
        for original in StarCatalog.prototype {
            XCTAssertEqual(SkyCatalog.stars.filter { $0.id == original.id }, [original])
        }
    }
    func testEveryConstellationHasRealConnectedStarEndpoints() {
        let ids = Set(SkyCatalog.stars.map(\.id))
        for group in SkyCatalog.constellations {
            XCTAssertFalse(group.links.isEmpty, "No figure for \(group.id)")
            XCTAssertTrue(Set(group.starIDs).isSubset(of: ids))
            for (a, b) in group.links {
                XCTAssertNotEqual(a, b)
                XCTAssertTrue(group.starIDs.contains(a) && group.starIDs.contains(b))
            }
        }
    }
}
