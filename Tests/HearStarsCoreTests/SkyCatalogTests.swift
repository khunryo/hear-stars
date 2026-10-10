import XCTest
@testable import HearStarsCore

final class SkyCatalogTests: XCTestCase {
    private func h(_ azimuth: Double, _ altitude: Double = 30) -> HorizontalCoordinate {
        .init(azimuthDegrees: azimuth, altitudeDegrees: altitude, localHourAngleDegrees: 0)
    }
    func testCatalogHasUniqueFiniteStarsAndPreservesOriginalFive() {
        XCTAssertEqual(SkyCatalog.stars.count, 31)
        XCTAssertEqual(Set(SkyCatalog.stars.map(\.id)).count, 31)
        for original in StarCatalog.prototype {
            XCTAssertTrue(SkyCatalog.stars.contains { $0.id == original.id && $0.j2000 == original.j2000 })
        }
        for star in SkyCatalog.stars {
            XCTAssertTrue(star.j2000.rightAscensionDegrees.isFinite)
            XCTAssertTrue(star.j2000.declinationDegrees.isFinite)
            XCTAssertTrue(star.visualMagnitude.isFinite)
        }
    }
    func testOriginalConnectionsHaveRealEndpointsInTheirOwnGroup() {
        let ids = Set(SkyCatalog.stars.map(\.id))
        XCTAssertEqual(SkyCatalog.constellations.count, 6)
        for group in SkyCatalog.constellations {
            XCTAssertTrue(Set(group.starIDs).isSubset(of: ids))
            for (a, b) in group.links {
                XCTAssertNotEqual(a, b)
                XCTAssertTrue(group.starIDs.contains(a) && group.starIDs.contains(b))
            }
        }
    }
    func testNextStarPrefersSameConstellationThenNearestAngularNeighbor() {
        let observations = ["polaris": h(0), "kochab": h(20), "pherkad": h(10), "vega": h(1)]
        XCTAssertEqual(SkyCatalog.nextStar(after: "polaris", observations: observations)?.id, "pherkad")
    }
    func testNextStarExcludesSelectedLowDimAndMissingStars() {
        let observations = ["polaris": h(0), "kochab": h(1, 4.9), "yildun": h(2), "vega": h(10, 5)]
        XCTAssertEqual(SkyCatalog.nextStar(after: "polaris", observations: observations)?.id, "vega")
        XCTAssertNil(SkyCatalog.nextStar(after: "missing", observations: observations))
        XCTAssertNil(SkyCatalog.nextStar(after: "polaris", observations: ["polaris": h(0)]))
    }
    func testUnrelatedStarsAreNotAssignedAnOrionFallback() {
        XCTAssertEqual(SkyCatalog.constellation(for: "dubhe")?.id, "uma")
        XCTAssertNil(SkyCatalog.constellation(for: "unknown"))
    }
}
