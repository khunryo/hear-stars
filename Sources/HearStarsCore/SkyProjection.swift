import Foundation

/// Local East-North-Up axes; independent of UIKit and camera hardware.
public struct SkyVector: Equatable, Sendable {
    public let east: Double
    public let north: Double
    public let up: Double
    public init(east: Double, north: Double, up: Double) {
        self.east = east; self.north = north; self.up = up
    }
    init(_ coordinate: HorizontalCoordinate) {
        let a = AngleMath.radians(coordinate.azimuthDegrees)
        let h = AngleMath.radians(coordinate.altitudeDegrees)
        self.init(east: cos(h) * sin(a), north: cos(h) * cos(a), up: sin(h))
    }
    var isFinite: Bool { east.isFinite && north.isFinite && up.isFinite }
    var length: Double { sqrt(dot(self)) }
    var normalized: Self? {
        guard isFinite, length > 1e-10 else { return nil }
        return scaled(1 / length)
    }
    func dot(_ v: Self) -> Double { east * v.east + north * v.north + up * v.up }
    func cross(_ v: Self) -> Self {
        .init(east: north * v.up - up * v.north,
              north: up * v.east - east * v.up, up: east * v.north - north * v.east)
    }
    func scaled(_ s: Double) -> Self { .init(east: east * s, north: north * s, up: up * s) }
    func adding(_ v: Self) -> Self { .init(east: east + v.east, north: north + v.north, up: up + v.up) }
}
public struct SkyPose: Equatable, Sendable {
    public let forward: SkyVector
    public let up: SkyVector
    public init(aim: DeviceAim, cameraUp: SkyVector? = nil) {
        forward = SkyVector(.init(azimuthDegrees: aim.azimuthDegrees,
            altitudeDegrees: aim.altitudeDegrees, localHourAngleDegrees: 0))
        let a = AngleMath.radians(aim.azimuthDegrees)
        let h = AngleMath.radians(aim.altitudeDegrees)
        up = cameraUp ?? .init(east: -sin(h) * sin(a), north: -sin(h) * cos(a), up: cos(h))
    }
    init(forward: SkyVector, up: SkyVector) { self.forward = forward; self.up = up }
}
public struct SkyViewport: Equatable, Sendable {
    public let width: Double
    public let height: Double
    let focalLength: Double
    public init(width: Double, height: Double, horizontalFieldOfViewDegrees: Double = 75) {
        self.width = width; self.height = height
        focalLength = horizontalFieldOfViewDegrees > 0 && horizontalFieldOfViewDegrees < 170
            ? width / (2 * tan(AngleMath.radians(horizontalFieldOfViewDegrees) / 2)) : .nan
    }
    private init(width: Double, height: Double, focalLength: Double) {
        self.width = width; self.height = height; self.focalLength = focalLength
    }
    /// A rear sensor is landscape-native, rotated 90° for a portrait aspect-fill preview.
    public static func camera(width: Double, height: Double,
        landscapeFieldOfViewDegrees: Double, landscapeAspectRatio: Double) -> Self {
        guard landscapeAspectRatio.isFinite, landscapeAspectRatio > 0,
              landscapeFieldOfViewDegrees > 0, landscapeFieldOfViewDegrees < 170 else {
            return .init(width: width, height: height, focalLength: .nan)
        }
        let sensorWidth = landscapeAspectRatio
        let scale = max(width, height / sensorWidth)
        let focal = sensorWidth / (2 * tan(AngleMath.radians(landscapeFieldOfViewDegrees) / 2))
        return .init(width: width, height: height, focalLength: focal * scale)
    }
}
public struct SkyPoint: Equatable, Sendable {
    public let x: Double
    public let y: Double
}
public enum SkyProjection {
    public static func project(_ target: HorizontalCoordinate, pose: SkyPose, viewport: SkyViewport) -> SkyPoint? {
        guard target.altitudeDegrees >= 0, viewport.width.isFinite, viewport.width > 0,
              viewport.height.isFinite, viewport.height > 0,
              viewport.focalLength.isFinite, viewport.focalLength > 0,
              let forward = pose.forward.normalized,
              let right = forward.cross(pose.up).normalized else { return nil }
        let up = right.cross(forward)
        let star = SkyVector(target)
        let depth = star.dot(forward)
        guard star.isFinite, depth > 1e-6 else { return nil }
        let x = 0.5 + star.dot(right) / depth * viewport.focalLength / viewport.width
        let y = 0.5 - star.dot(up) / depth * viewport.focalLength / viewport.height
        guard x.isFinite, y.isFinite else { return nil }
        return .init(x: x, y: y)
    }
}
public struct SkyAlignment: Equatable, Sendable {
    private let axis: SkyVector
    private let angle: Double
    /// One known star corrects the local offset, not sensor accuracy or roll calibration.
    public init?(matching pose: SkyPose, to target: HorizontalCoordinate) {
        guard target.altitudeDegrees >= 0, let from = pose.forward.normalized,
              let to = SkyVector(target).normalized else { return nil }
        let angle = acos(AngleMath.clamp(from.dot(to), min: -1, max: 1))
        guard angle.isFinite, angle <= AngleMath.radians(25) + 1e-12 else { return nil }
        self.angle = angle
        axis = from.cross(to).normalized ?? .init(east: 0, north: 0, up: 1)
    }
    private func rotate(_ v: SkyVector) -> SkyVector {
        v.scaled(cos(angle)).adding(axis.cross(v).scaled(sin(angle)))
            .adding(axis.scaled(axis.dot(v) * (1 - cos(angle))))
    }
    public func applying(to pose: SkyPose) -> SkyPose {
        .init(forward: rotate(pose.forward), up: rotate(pose.up))
    }
}
