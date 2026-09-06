import Foundation

// This file uses computations reimplemented from the IAU SOFA GMST06 and
// Fukushima-Williams bias-precession algorithms. It is a clean Swift
// implementation of the published formulae and does not constitute software
// provided or endorsed by the IAU SOFA Board. Unlike the complete SOFA chain,
// Phase 1 uses Foundation.Date, UT1≈UTC, a fixed TT−UTC value, catalog proper
// motion, and deliberately omits nutation, aberration, parallax, and refraction.
// See docs/ASTRONOMY-VALIDATION.md and docs/SOFA-NOTICE.md.

public struct ObserverLocation: Equatable, Sendable {
    public let latitudeDegrees: Double
    public let longitudeDegrees: Double

    public init(latitudeDegrees: Double, longitudeDegrees: Double) {
        self.latitudeDegrees = AngleMath.clamp(latitudeDegrees, min: -90.0, max: 90.0)
        self.longitudeDegrees = AngleMath.signedDegrees(longitudeDegrees)
    }
}

public struct HorizontalCoordinate: Equatable, Sendable {
    /// Degrees clockwise from true north, normalized to 0..<360.
    public let azimuthDegrees: Double
    /// Geometric altitude in degrees. Atmospheric refraction is not applied.
    public let altitudeDegrees: Double
    public let localHourAngleDegrees: Double

    public var isAboveGeometricHorizon: Bool { altitudeDegrees >= 0.0 }
    public var isClearOfLowHorizon: Bool { altitudeDegrees >= 5.0 }

    public init(azimuthDegrees: Double, altitudeDegrees: Double, localHourAngleDegrees: Double) {
        self.azimuthDegrees = AngleMath.normalizeDegrees(azimuthDegrees)
        self.altitudeDegrees = AngleMath.clamp(altitudeDegrees, min: -90.0, max: 90.0)
        self.localHourAngleDegrees = AngleMath.signedDegrees(localHourAngleDegrees)
    }
}

public enum AstronomyCalculator {
    public static let j2000JulianDate = 2_451_545.0
    /// Phase 1 approximation for the present validation epoch. Replace with a
    /// maintained leap-second table when the official SOFA bridge is integrated.
    public static let approximateTTMinusUTCSeconds = 69.184

    public static func julianDate(for date: Date) -> Double {
        date.timeIntervalSince1970 / 86_400.0 + 2_440_587.5
    }

    /// IAU 2006 GMST using ERA, with Phase 1 approximations UT1≈UTC and
    /// TT≈UTC+69.184 s. This must be paired with mean-of-date coordinates.
    public static func greenwichMeanSiderealDegrees(for date: Date) -> Double {
        let jdUTC = julianDate(for: date)
        let jdUT1 = jdUTC
        let jdTT = jdUTC + approximateTTMinusUTCSeconds / 86_400.0
        let daysFromJ2000 = jdUT1 - j2000JulianDate
        let t = (jdTT - j2000JulianDate) / 36_525.0

        let era = AngleMath.normalizeRadians(
            2.0 * Double.pi
                * (0.779_057_273_264_0 + 1.002_737_811_911_354_48 * daysFromJ2000)
        )
        let precessionArcseconds = 0.014_506
            + 4_612.156_534 * t
            + 1.391_581_7 * t * t
            - 0.000_000_44 * pow(t, 3)
            - 0.000_029_956 * pow(t, 4)
            - 0.000_000_036_8 * pow(t, 5)
        let gmst = era + precessionArcseconds * AngleMath.radiansPerArcsecond
        return AngleMath.normalizeDegrees(AngleMath.degrees(gmst))
    }

    public static func meanCoordinateOfDate(for star: Star, at date: Date) -> EquatorialCoordinate {
        let jdUTC = julianDate(for: date)
        let years = (jdUTC - j2000JulianDate) / 365.25
        let moved = UnitVector(equatorial: star.j2000).applying(
            properMotion: star.properMotion,
            julianYears: years
        )
        let jdTT = jdUTC + approximateTTMinusUTCSeconds / 86_400.0
        return (biasPrecessionMatrix(julianDateTT: jdTT) * moved).normalized.equatorial
    }

    public static func horizontalCoordinate(
        for star: Star,
        at date: Date,
        observer: ObserverLocation
    ) -> HorizontalCoordinate {
        let coordinate = meanCoordinateOfDate(for: star, at: date)
        let localSidereal = AngleMath.normalizeDegrees(
            greenwichMeanSiderealDegrees(for: date) + observer.longitudeDegrees
        )
        let hourAngleDegrees = AngleMath.signedDegrees(localSidereal - coordinate.rightAscensionDegrees)

        let hourAngle = AngleMath.radians(hourAngleDegrees)
        let declination = AngleMath.radians(coordinate.declinationDegrees)
        let latitude = AngleMath.radians(observer.latitudeDegrees)

        // Equatorial to local East-North-Up. This avoids azimuth quadrant ambiguity.
        let east = -cos(declination) * sin(hourAngle)
        let north = sin(declination) * cos(latitude)
            - cos(declination) * cos(hourAngle) * sin(latitude)
        let up = sin(declination) * sin(latitude)
            + cos(declination) * cos(hourAngle) * cos(latitude)

        let azimuth = AngleMath.normalizeDegrees(AngleMath.degrees(atan2(east, north)))
        let altitude = AngleMath.degrees(atan2(up, hypot(east, north)))

        return HorizontalCoordinate(
            azimuthDegrees: azimuth,
            altitudeDegrees: altitude,
            localHourAngleDegrees: hourAngleDegrees
        )
    }

    /// IAU 2006 P03 Fukushima-Williams bias-precession matrix. Rotation
    /// conventions intentionally match the published SOFA formulation.
    static func biasPrecessionMatrix(julianDateTT: Double) -> Matrix3D {
        let t = (julianDateTT - j2000JulianDate) / 36_525.0
        let gamb = polynomial(t, -0.052_928, 10.556_378, 0.493_204_4, -0.000_312_38, -0.000_002_788, 0.000_000_026_0)
            * AngleMath.radiansPerArcsecond
        let phib = polynomial(t, 84_381.412_819, -46.811_016, 0.051_126_8, 0.000_532_89, -0.000_000_440, -0.000_000_017_6)
            * AngleMath.radiansPerArcsecond
        let psib = polynomial(t, -0.041_775, 5_038.481_484, 1.558_417_5, -0.000_185_22, -0.000_026_452, -0.000_000_014_8)
            * AngleMath.radiansPerArcsecond
        let epsa = polynomial(t, 84_381.406, -46.836_769, -0.000_183_1, 0.002_003_40, -0.000_000_576, -0.000_000_043_4)
            * AngleMath.radiansPerArcsecond

        return Matrix3D.rotation1(-epsa)
            * Matrix3D.rotation3(-psib)
            * Matrix3D.rotation1(phib)
            * Matrix3D.rotation3(gamb)
    }

    private static func polynomial(_ t: Double, _ coefficients: Double...) -> Double {
        coefficients.reversed().reduce(0.0) { partial, coefficient in
            partial * t + coefficient
        }
    }
}

struct UnitVector: Equatable, Sendable {
    let x: Double
    let y: Double
    let z: Double

    init(x: Double, y: Double, z: Double) {
        self.x = x
        self.y = y
        self.z = z
    }

    init(equatorial: EquatorialCoordinate) {
        let ra = AngleMath.radians(equatorial.rightAscensionDegrees)
        let dec = AngleMath.radians(equatorial.declinationDegrees)
        self.init(x: cos(dec) * cos(ra), y: cos(dec) * sin(ra), z: sin(dec))
    }

    var length: Double { sqrt(x * x + y * y + z * z) }

    var normalized: Self {
        let divisor = max(length, 1e-15)
        return .init(x: x / divisor, y: y / divisor, z: z / divisor)
    }

    var equatorial: EquatorialCoordinate {
        let unit = normalized
        return EquatorialCoordinate(
            rightAscensionDegrees: AngleMath.normalizeDegrees(AngleMath.degrees(atan2(unit.y, unit.x))),
            declinationDegrees: AngleMath.degrees(atan2(unit.z, hypot(unit.x, unit.y)))
        )
    }

    func applying(properMotion: ProperMotion, julianYears: Double) -> Self {
        let coordinate = equatorial
        let ra = AngleMath.radians(coordinate.rightAscensionDegrees)
        let dec = AngleMath.radians(coordinate.declinationDegrees)
        let alphaBasis = Self(x: -sin(ra), y: cos(ra), z: 0)
        let declinationBasis = Self(
            x: -sin(dec) * cos(ra),
            y: -sin(dec) * sin(ra),
            z: cos(dec)
        )
        let scale = julianYears * AngleMath.radiansPerMilliarcsecond
        return Self(
            x: x + scale * (properMotion.rightAscensionMasPerYear * alphaBasis.x + properMotion.declinationMasPerYear * declinationBasis.x),
            y: y + scale * (properMotion.rightAscensionMasPerYear * alphaBasis.y + properMotion.declinationMasPerYear * declinationBasis.y),
            z: z + scale * (properMotion.rightAscensionMasPerYear * alphaBasis.z + properMotion.declinationMasPerYear * declinationBasis.z)
        ).normalized
    }
}

struct Matrix3D: Equatable, Sendable {
    let rows: [[Double]]

    init(_ rows: [[Double]]) {
        precondition(rows.count == 3 && rows.allSatisfy { $0.count == 3 })
        self.rows = rows
    }

    /// SOFA-style passive rotation around the x axis.
    static func rotation1(_ angle: Double) -> Self {
        let c = cos(angle)
        let s = sin(angle)
        return .init([[1, 0, 0], [0, c, s], [0, -s, c]])
    }

    /// SOFA-style passive rotation around the z axis.
    static func rotation3(_ angle: Double) -> Self {
        let c = cos(angle)
        let s = sin(angle)
        return .init([[c, s, 0], [-s, c, 0], [0, 0, 1]])
    }

    static func * (lhs: Self, rhs: Self) -> Self {
        .init((0..<3).map { row in
            (0..<3).map { column in
                (0..<3).reduce(0.0) { $0 + lhs.rows[row][$1] * rhs.rows[$1][column] }
            }
        })
    }

    static func * (lhs: Self, rhs: UnitVector) -> UnitVector {
        let vector = [rhs.x, rhs.y, rhs.z]
        let result = (0..<3).map { row in
            (0..<3).reduce(0.0) { $0 + lhs.rows[row][$1] * vector[$1] }
        }
        return .init(x: result[0], y: result[1], z: result[2])
    }
}
