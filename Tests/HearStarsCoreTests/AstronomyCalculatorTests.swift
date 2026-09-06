import XCTest
@testable import HearStarsCore

final class AstronomyCalculatorTests: XCTestCase {
    private let fixtureDate = ISO8601DateFormatter().date(from: "2026-01-15T12:00:00Z")!
    private let tokyo = ObserverLocation(latitudeDegrees: 35.681236, longitudeDegrees: 139.767125)

    func testJulianDateEpochs() {
        let unixEpoch = ISO8601DateFormatter().date(from: "1970-01-01T00:00:00Z")!
        let j2000 = ISO8601DateFormatter().date(from: "2000-01-01T12:00:00Z")!
        XCTAssertEqual(AstronomyCalculator.julianDate(for: unixEpoch), 2_440_587.5, accuracy: 1e-10)
        XCTAssertEqual(AstronomyCalculator.julianDate(for: j2000), 2_451_545.0, accuracy: 1e-10)
    }

    func testCoordinateInputsAreNormalizedAtTheBoundary() {
        let observer = ObserverLocation(latitudeDegrees: 95, longitudeDegrees: 540)
        XCTAssertEqual(observer.latitudeDegrees, 90, accuracy: 1e-12)
        XCTAssertEqual(observer.longitudeDegrees, -180, accuracy: 1e-12)

        let horizontal = HorizontalCoordinate(
            azimuthDegrees: -1,
            altitudeDegrees: -95,
            localHourAngleDegrees: 180
        )
        XCTAssertEqual(horizontal.azimuthDegrees, 359, accuracy: 1e-12)
        XCTAssertEqual(horizontal.altitudeDegrees, -90, accuracy: 1e-12)
        XCTAssertEqual(horizontal.localHourAngleDegrees, -180, accuracy: 1e-12)

        let equatorial = EquatorialCoordinate(
            rightAscensionDegrees: 361,
            declinationDegrees: 91
        )
        XCTAssertEqual(equatorial.rightAscensionDegrees, 1, accuracy: 1e-12)
        XCTAssertEqual(equatorial.declinationDegrees, 90, accuracy: 1e-12)
    }

    func testGMST06ReferenceFixture() {
        XCTAssertEqual(
            AstronomyCalculator.greenwichMeanSiderealDegrees(for: fixtureDate),
            294.952_729_443,
            accuracy: 1e-9
        )
    }

    func testMeanOfDateReferenceFixtures() {
        assertMeanCoordinate(
            ra: 37.954_560_67,
            dec: 89.264_108_97,
            expectedRA: 46.476_709_119,
            expectedDec: 89.371_738_133
        )
        assertMeanCoordinate(
            ra: 101.287_155_33,
            dec: -16.716_115_86,
            expectedRA: 101.578_086_872,
            expectedDec: -16.744_851_937
        )
        assertMeanCoordinate(
            ra: 88.792_938_99,
            dec: 7.407_064_00,
            expectedRA: 89.145_423_437,
            expectedDec: 7.409_668_022
        )
        assertMeanCoordinate(
            ra: 279.234_734_79,
            dec: 38.783_688_96,
            expectedRA: 279.453_392_796,
            expectedDec: 38.807_228_030
        )
    }

    func testTokyoHorizontalReferenceFixtures() {
        assertHorizontal(
            ra: 37.954_560_67,
            dec: 89.264_108_97,
            expectedAzimuth: 359.631_421_348,
            expectedAltitude: 36.234_141_368
        )
        assertHorizontal(
            ra: 101.287_155_33,
            dec: -16.716_115_86,
            expectedAzimuth: 149.426_830_810,
            expectedAltitude: 31.727_326_699
        )
        assertHorizontal(
            ra: 88.792_938_99,
            dec: 7.407_064_00,
            expectedAzimuth: 151.522_213_209,
            expectedAltitude: 58.794_776_608
        )
        let vega = fixtureStar(ra: 279.234_734_79, dec: 38.783_688_96)
        let result = AstronomyCalculator.horizontalCoordinate(for: vega, at: fixtureDate, observer: tokyo)
        XCTAssertEqual(result.azimuthDegrees, 340.522_863_354, accuracy: 1e-8)
        XCTAssertEqual(result.altitudeDegrees, -12.085_182_284, accuracy: 1e-8)
        XCTAssertFalse(result.isAboveGeometricHorizon)
    }

    func testProperMotionUsesVectorBasisNearPole() {
        let almostPole = UnitVector(
            equatorial: .init(rightAscensionDegrees: 12, declinationDegrees: 89.999)
        )
        let moved = almostPole.applying(
            properMotion: .init(rightAscensionMasPerYear: 1_000, declinationMasPerYear: 0),
            julianYears: 10
        )
        XCTAssertTrue(moved.x.isFinite)
        XCTAssertTrue(moved.y.isFinite)
        XCTAssertTrue(moved.z.isFinite)
        XCTAssertEqual(moved.length, 1, accuracy: 1e-12)
    }

    func testBiasPrecessionMatrixIsProperRotation() {
        let jdTT = AstronomyCalculator.julianDate(for: fixtureDate)
            + AstronomyCalculator.approximateTTMinusUTCSeconds / 86_400
        let matrix = AstronomyCalculator.biasPrecessionMatrix(julianDateTT: jdTT)
        for row in 0..<3 {
            let length = sqrt((0..<3).reduce(0.0) { $0 + matrix.rows[row][$1] * matrix.rows[row][$1] })
            XCTAssertEqual(length, 1, accuracy: 1e-12)
        }
        let determinant =
            matrix.rows[0][0] * (matrix.rows[1][1] * matrix.rows[2][2] - matrix.rows[1][2] * matrix.rows[2][1])
            - matrix.rows[0][1] * (matrix.rows[1][0] * matrix.rows[2][2] - matrix.rows[1][2] * matrix.rows[2][0])
            + matrix.rows[0][2] * (matrix.rows[1][0] * matrix.rows[2][1] - matrix.rows[1][1] * matrix.rows[2][0])
        XCTAssertEqual(determinant, 1, accuracy: 1e-12)
    }

    private func assertMeanCoordinate(
        ra: Double,
        dec: Double,
        expectedRA: Double,
        expectedDec: Double,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        let result = AstronomyCalculator.meanCoordinateOfDate(
            for: fixtureStar(ra: ra, dec: dec),
            at: fixtureDate
        )
        XCTAssertEqual(result.rightAscensionDegrees, expectedRA, accuracy: 1e-8, file: file, line: line)
        XCTAssertEqual(result.declinationDegrees, expectedDec, accuracy: 1e-8, file: file, line: line)
    }

    private func assertHorizontal(
        ra: Double,
        dec: Double,
        expectedAzimuth: Double,
        expectedAltitude: Double,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        let result = AstronomyCalculator.horizontalCoordinate(
            for: fixtureStar(ra: ra, dec: dec),
            at: fixtureDate,
            observer: tokyo
        )
        XCTAssertEqual(result.azimuthDegrees, expectedAzimuth, accuracy: 1e-8, file: file, line: line)
        XCTAssertEqual(result.altitudeDegrees, expectedAltitude, accuracy: 1e-8, file: file, line: line)
    }

    private func fixtureStar(ra: Double, dec: Double) -> Star {
        Star(
            id: "fixture",
            nameKey: "fixture",
            designation: "fixture",
            constellation: "fixture",
            j2000: .init(rightAscensionDegrees: ra, declinationDegrees: dec),
            properMotion: .init(rightAscensionMasPerYear: 0, declinationMasPerYear: 0),
            visualMagnitude: 0,
            discoveryPattern: .init(semitoneOffsets: [0], hapticDurations: [0.1])
        )
    }
}
