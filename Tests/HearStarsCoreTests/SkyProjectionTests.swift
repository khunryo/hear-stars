import XCTest
@testable import HearStarsCore

final class SkyProjectionTests: XCTestCase {
    private func horizontal(_ azimuth: Double, _ altitude: Double = 0) -> HorizontalCoordinate {
        .init(azimuthDegrees: azimuth, altitudeDegrees: altitude, localHourAngleDegrees: 0)
    }
    private let square = SkyViewport(width: 400, height: 400, horizontalFieldOfViewDegrees: 90)

    func testTargetAtOpticalAxisIsCentered() throws {
        let pose = SkyPose(aim: .init(azimuthDegrees: 0, altitudeDegrees: 30))
        let p = try XCTUnwrap(SkyProjection.project(horizontal(0, 30), pose: pose, viewport: square))
        XCTAssertEqual(p.x, 0.5, accuracy: 1e-9)
        XCTAssertEqual(p.y, 0.5, accuracy: 1e-9)
    }
    func testEastIsRightAndHigherAltitudeIsUp() throws {
        let pose = SkyPose(aim: .init(azimuthDegrees: 0, altitudeDegrees: 0))
        let east = try XCTUnwrap(SkyProjection.project(horizontal(10), pose: pose, viewport: square))
        let up = try XCTUnwrap(SkyProjection.project(horizontal(0, 10), pose: pose, viewport: square))
        XCTAssertEqual(east.x, 0.5881634904, accuracy: 1e-9)
        XCTAssertEqual(east.y, 0.5, accuracy: 1e-9)
        XCTAssertEqual(up.x, 0.5, accuracy: 1e-9)
        XCTAssertEqual(up.y, 0.4118365096, accuracy: 1e-9)
    }
    func testNorthWrapTakesTwoDegreePath() throws {
        let p = try XCTUnwrap(SkyProjection.project(horizontal(1),
            pose: SkyPose(aim: .init(azimuthDegrees: 359, altitudeDegrees: 0)), viewport: square))
        XCTAssertEqual(p.x, 0.5174603847, accuracy: 1e-9)
    }
    func testBackAndSideFacingStarsAreNotProjected() {
        let pose = SkyPose(aim: .init(azimuthDegrees: 0, altitudeDegrees: 0))
        XCTAssertNil(SkyProjection.project(horizontal(180), pose: pose, viewport: square))
        XCTAssertNil(SkyProjection.project(horizontal(90), pose: pose, viewport: square))
    }
    func testBelowHorizonAndInvalidViewportDoNotProduceStars() {
        let pose = SkyPose(aim: .init(azimuthDegrees: 0, altitudeDegrees: 0))
        XCTAssertNil(SkyProjection.project(horizontal(0, -1), pose: pose, viewport: square))
        XCTAssertNil(SkyProjection.project(horizontal(0), pose: pose,
            viewport: .init(width: 0, height: 400, horizontalFieldOfViewDegrees: 90)))
        XCTAssertNil(SkyProjection.project(horizontal(0), pose: pose,
            viewport: .init(width: 400, height: 400, horizontalFieldOfViewDegrees: .nan)))
    }
    func testCameraRollRotatesStarField() throws {
        let pose = SkyPose(aim: .init(azimuthDegrees: 0, altitudeDegrees: 0),
                           cameraUp: .init(east: 1, north: 0, up: 0))
        let p = try XCTUnwrap(SkyProjection.project(horizontal(10), pose: pose, viewport: square))
        XCTAssertEqual(p.x, 0.5, accuracy: 1e-9)
        XCTAssertEqual(p.y, 0.4118365096, accuracy: 1e-9)
    }
    func testZenithRetainsMeasuredCameraOrientation() throws {
        let pose = SkyPose(aim: .init(azimuthDegrees: 0, altitudeDegrees: 90),
                           cameraUp: .init(east: 0, north: -1, up: 0))
        let p = try XCTUnwrap(SkyProjection.project(horizontal(90, 80), pose: pose, viewport: square))
        XCTAssertEqual(p.x, 0.5881634904, accuracy: 1e-9)
        XCTAssertEqual(p.y, 0.5, accuracy: 1e-9)
    }
    func testPortraitCameraCropUsesActualFocalScale() throws {
        let viewport = SkyViewport.camera(width: 300, height: 600,
            landscapeFieldOfViewDegrees: 90, landscapeAspectRatio: 4.0 / 3)
        let p = try XCTUnwrap(SkyProjection.project(horizontal(10),
            pose: SkyPose(aim: .init(azimuthDegrees: 0, altitudeDegrees: 0)), viewport: viewport))
        XCTAssertEqual(p.x, 0.6763269807, accuracy: 1e-9)
        XCTAssertEqual(p.y, 0.5, accuracy: 1e-9)
    }
    func testManualAlignmentCentersKnownStar() throws {
        let pose = SkyPose(aim: .init(azimuthDegrees: 10, altitudeDegrees: 20))
        let alignment = try XCTUnwrap(SkyAlignment(matching: pose, to: horizontal(0, 25)))
        let p = try XCTUnwrap(SkyProjection.project(horizontal(0, 25),
            pose: alignment.applying(to: pose), viewport: square))
        XCTAssertEqual(p.x, 0.5, accuracy: 1e-9)
        XCTAssertEqual(p.y, 0.5, accuracy: 1e-9)
    }
    func testAlignmentRejectsWrongStarAndBelowHorizon() {
        let pose = SkyPose(aim: .init(azimuthDegrees: 0, altitudeDegrees: 0))
        XCTAssertNil(SkyAlignment(matching: pose, to: horizontal(90)))
        XCTAssertNil(SkyAlignment(matching: pose, to: horizontal(0, -1)))
    }
    func testAlignmentPreservesAngularSeparationForNeighbors() throws {
        let pose = SkyPose(aim: .init(azimuthDegrees: 10, altitudeDegrees: 0))
        let alignment = try XCTUnwrap(SkyAlignment(matching: pose, to: horizontal(0)))
        let turned = SkyPose(aim: .init(azimuthDegrees: 20, altitudeDegrees: 0))
        let p = try XCTUnwrap(SkyProjection.project(horizontal(10),
            pose: alignment.applying(to: turned), viewport: square))
        XCTAssertEqual(p.x, 0.5, accuracy: 1e-9)
        XCTAssertEqual(p.y, 0.5, accuracy: 1e-9)
    }
}
