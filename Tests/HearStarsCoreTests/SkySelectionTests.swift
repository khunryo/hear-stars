import XCTest
@testable import HearStarsCore

final class SkySelectionTests: XCTestCase {
    private let viewport = SkyViewport(width: 400, height: 400)
    private func h(_ altitude: Double) -> HorizontalCoordinate {
        .init(azimuthDegrees: 0, altitudeDegrees: altitude, localHourAngleDegrees: 0)
    }
    func testTapPicksNearestRealRenderedCandidateWithinFriendlyRadius() {
        let dots = [SkyPickCandidate(.star("a"), at: .init(x: 0.5, y: 0.5)),
                    SkyPickCandidate(.star("b"), at: .init(x: 0.55, y: 0.5))]
        XCTAssertEqual(SkyPicking.nearest(to: .init(x: 0.54, y: 0.5), candidates: dots, viewport: viewport), .star("b"))
        XCTAssertNil(SkyPicking.nearest(to: .init(x: 0.8, y: 0.5), candidates: dots, viewport: viewport))
    }
    func testCoincidentLabelHasPriorityOverStarAndInvalidInputHasNoPick() {
        let dots = [SkyPickCandidate(.star("a"), at: .init(x: 0.5, y: 0.5)),
                    SkyPickCandidate(.constellation("ori"), at: .init(x: 0.5, y: 0.5), priority: 1)]
        XCTAssertEqual(SkyPicking.nearest(to: .init(x: 0.5, y: 0.5), candidates: dots, viewport: viewport), .constellation("ori"))
        XCTAssertNil(SkyPicking.nearest(to: .init(x: .nan, y: 0), candidates: dots, viewport: viewport))
        XCTAssertNil(SkyPicking.nearest(to: .init(x: 0.5, y: 0.5), candidates: dots, viewport: .init(width: 0, height: 1)))
    }
    func testConstellationGuideUsesBrightestVisibleMember() {
        let observations = ["rigel": h(30), "betelgeuse": h(20), "bellatrix": h(40)]
        XCTAssertEqual(SkySelectionResolver.star(for: .constellation("ori"), observations: observations)?.id, "rigel")
    }
    func testConstellationSkipsLowHorizonAndReturnsNilForInvisibleOrUnknownFigure() {
        let observations = ["rigel": h(4.99), "betelgeuse": h(20), "bellatrix": h(-5)]
        XCTAssertEqual(SkySelectionResolver.star(for: .constellation("ori"), observations: observations)?.id, "betelgeuse")
        XCTAssertNil(SkySelectionResolver.star(for: .constellation("ori"), observations: ["rigel": h(-1)]))
        XCTAssertNil(SkySelectionResolver.star(for: .constellation("unknown"), observations: observations))
    }
    func testSingleStarKeepsIdentityAndCannotGuideBelowExistingHorizonGate() {
        XCTAssertEqual(SkySelectionResolver.star(for: .star("vega"), observations: ["vega": h(2)])?.id, "vega")
        XCTAssertNil(SkySelectionResolver.star(for: .star("vega"), observations: ["vega": h(1.99)]))
        XCTAssertNil(SkySelectionResolver.star(for: .star("missing"), observations: ["missing": h(20)]))
    }
    func testExpensiveWorldCoordinatesAreThrottledButLocationAndModeChangesInvalidate() {
        var schedule = SkyObservationSchedule()
        let observer = ObserverLocation(latitudeDegrees: 35, longitudeDegrees: 139)
        let date = Date(timeIntervalSince1970: 100)
        XCTAssertTrue(schedule.shouldRecalculate(at: date, observer: observer, isPractice: false))
        XCTAssertFalse(schedule.shouldRecalculate(at: date.addingTimeInterval(0.1), observer: observer, isPractice: false))
        XCTAssertTrue(schedule.shouldRecalculate(at: date.addingTimeInterval(1), observer: observer, isPractice: false))
        XCTAssertTrue(schedule.shouldRecalculate(at: date.addingTimeInterval(1.1),
            observer: .init(latitudeDegrees: -35, longitudeDegrees: 139), isPractice: false))
        XCTAssertTrue(schedule.shouldRecalculate(at: date.addingTimeInterval(1.2), observer: observer, isPractice: true))
        XCTAssertFalse(schedule.shouldRecalculate(at: date.addingTimeInterval(1.2), observer: observer, isPractice: true))
    }
}
