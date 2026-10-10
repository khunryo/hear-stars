import Foundation

// Initial API for the executable RED phase. Implement after observing failures.
public struct SkyVector: Equatable, Sendable {
    public let east: Double
    public let north: Double
    public let up: Double
    public init(east: Double, north: Double, up: Double) {
        self.east = east; self.north = north; self.up = up
    }
}
public struct SkyPose: Equatable, Sendable {
    public let aim: DeviceAim
    public let cameraUp: SkyVector?
    public init(aim: DeviceAim, cameraUp: SkyVector? = nil) {
        self.aim = aim; self.cameraUp = cameraUp
    }
}
public struct SkyViewport: Equatable, Sendable {
    public init(width: Double, height: Double, horizontalFieldOfViewDegrees: Double) {}
    public static func camera(width: Double, height: Double,
        landscapeFieldOfViewDegrees: Double, landscapeAspectRatio: Double) -> Self {
        .init(width: width, height: height, horizontalFieldOfViewDegrees: landscapeFieldOfViewDegrees)
    }
}
public struct SkyPoint: Equatable, Sendable {
    public let x: Double
    public let y: Double
}
public enum SkyProjection {
    public static func project(_ target: HorizontalCoordinate, pose: SkyPose, viewport: SkyViewport) -> SkyPoint? { nil }
}
public struct SkyAlignment: Equatable, Sendable {
    public init?(matching pose: SkyPose, to target: HorizontalCoordinate) { return nil }
    public func applying(to pose: SkyPose) -> SkyPose { pose }
}
