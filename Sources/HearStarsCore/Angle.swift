import Foundation

public enum AngleMath {
    public static let degreesPerRadian = 180.0 / Double.pi
    public static let radiansPerDegree = Double.pi / 180.0
    public static let radiansPerArcsecond = Double.pi / (180.0 * 3_600.0)
    public static let radiansPerMilliarcsecond = Double.pi / (180.0 * 3_600_000.0)

    public static func radians(_ degrees: Double) -> Double {
        degrees * radiansPerDegree
    }

    public static func degrees(_ radians: Double) -> Double {
        radians * degreesPerRadian
    }

    public static func normalizeDegrees(_ value: Double) -> Double {
        let remainder = value.truncatingRemainder(dividingBy: 360.0)
        return remainder < 0 ? remainder + 360.0 : remainder
    }

    public static func normalizeRadians(_ value: Double) -> Double {
        let turn = 2.0 * Double.pi
        let remainder = value.truncatingRemainder(dividingBy: turn)
        return remainder < 0 ? remainder + turn : remainder
    }

    public static func signedDegrees(_ value: Double) -> Double {
        let normalized = normalizeDegrees(value)
        return normalized >= 180.0 ? normalized - 360.0 : normalized
    }

    public static func clamp(_ value: Double, min lower: Double, max upper: Double) -> Double {
        Swift.max(lower, Swift.min(upper, value))
    }
}
