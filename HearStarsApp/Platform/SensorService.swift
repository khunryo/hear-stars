import Combine
import CoreLocation
import CoreMotion
import Foundation
import HearStarsCore

enum MovementSafetyStatus: Equatable {
    case ready
    case unavailable
    case awaitingAuthorization
    case awaitingStationaryConfirmation
    case denied
}

@MainActor
final class SensorService: NSObject, ObservableObject {
    @Published private(set) var location: CLLocation?
    @Published private(set) var aim: DeviceAim?
    @Published private(set) var headingAccuracyDegrees: Double?
    @Published private(set) var trueHeadingDegrees: Double?
    @Published private(set) var magneticHeadingDegrees: Double?
    @Published private(set) var authorizationStatus: CLAuthorizationStatus = .notDetermined
    @Published private(set) var isUnsafeMotion = false
    @Published private(set) var lastMotionAt: Date?
    @Published private(set) var usesTrueNorthReference = false
    @Published private(set) var gravityAlignmentErrorDegrees: Double?
    @Published private(set) var headingResidualDegrees: Double?
    @Published private(set) var magneticAccuracy: CMMagneticFieldCalibrationAccuracy = .uncalibrated
    @Published private(set) var hasStationaryConfirmation = false
    @Published private(set) var locationServicesAreEnabled = true

    private let locationManager = CLLocationManager()
    private let motionManager = CMMotionManager()
    private let activityManager = CMMotionActivityManager()
    private let motionQueue: OperationQueue = {
        let queue = OperationQueue()
        queue.name = "HearStars.DeviceMotion"
        queue.qualityOfService = .userInteractive
        queue.maxConcurrentOperationCount = 1
        return queue
    }()

    private var isRunning = false
    private var sensorGeneration: UInt64 = 0
    private var sessionStartedAt = Date.distantPast
    private var wantsLocationUpdates = false
    private var lastStableAzimuth: Double?
    private var lastMotionUptime: TimeInterval?
    private var lastHeadingAt: Date?
    private var lastHeadingUptime: TimeInterval?
    private var headingPairing = HeadingSamplePairing()
    private var headingReferenceOffsetDegrees = 0.0
    private var referenceKind: ReferenceKind = .arbitrary

    override init() {
        super.init()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyKilometer
        locationManager.distanceFilter = 1_000
        // Heading updates are change-driven, not a periodic heartbeat. Do not
        // suppress small changes while the user holds the phone toward a star.
        locationManager.headingFilter = kCLHeadingFilterNone
        locationManager.headingOrientation = .portrait
        locationManager.showsBackgroundLocationIndicator = false
        authorizationStatus = locationManager.authorizationStatus
    }

    func start(requestLocation: Bool) {
        wantsLocationUpdates = requestLocation
        if !requestLocation {
            locationManager.stopUpdatingLocation()
        }

        // Practice may already be running when the user switches to the live
        // sky. Location handling above must still occur in that case.
        if !isRunning {
            sensorGeneration &+= 1
            sessionStartedAt = Date()
            if requestLocation { location = nil }
            isRunning = true

            if CLLocationManager.headingAvailable() {
                locationManager.startUpdatingHeading()
            }
            startDeviceMotion()
            startActivityMonitoring()
        }

        guard requestLocation else { return }
        switch locationManager.authorizationStatus {
        case .notDetermined:
            locationManager.requestWhenInUseAuthorization()
        case .authorizedAlways, .authorizedWhenInUse:
            locationManager.startUpdatingLocation()
        default:
            break
        }
    }

    func stop() {
        isRunning = false
        sensorGeneration &+= 1
        wantsLocationUpdates = false
        locationManager.stopUpdatingLocation()
        locationManager.stopUpdatingHeading()
        motionManager.stopDeviceMotionUpdates()
        if CMMotionActivityManager.isActivityAvailable() {
            activityManager.stopActivityUpdates()
        }
        aim = nil
        lastMotionAt = nil
        lastMotionUptime = nil
        isUnsafeMotion = false
        hasStationaryConfirmation = false
        headingAccuracyDegrees = nil
        trueHeadingDegrees = nil
        magneticHeadingDegrees = nil
        lastHeadingAt = nil
        lastHeadingUptime = nil
        headingPairing.reset()
        headingReferenceOffsetDegrees = 0
        headingResidualDegrees = nil
        gravityAlignmentErrorDegrees = nil
        magneticAccuracy = .uncalibrated
        lastStableAzimuth = nil
        referenceKind = .arbitrary
    }

    var motionIsFresh: Bool {
        guard let lastMotionUptime else { return false }
        let age = ProcessInfo.processInfo.systemUptime - lastMotionUptime
        return age >= 0 && age <= 0.25
    }

    var headingAgeSeconds: TimeInterval? {
        lastHeadingUptime.map { max(0, ProcessInfo.processInfo.systemUptime - $0) }
    }

    var headingIsFresh: Bool {
        guard let age = headingAgeSeconds else { return false }
        return age <= 2.0
    }

    var headingDiagnosticSummary: String {
        func number(_ value: Double?) -> String {
            guard let value, value.isFinite else { return "—" }
            return String(format: "%.1f", locale: .current, value)
        }
        let magneticKey: String
        switch magneticAccuracy {
        case .uncalibrated: magneticKey = "diagnostics.magneticUncalibrated"
        case .low: magneticKey = "diagnostics.magneticLow"
        case .medium: magneticKey = "diagnostics.magneticMedium"
        case .high: magneticKey = "diagnostics.magneticHigh"
        @unknown default: magneticKey = "diagnostics.magneticUncalibrated"
        }
        return L10n.format("diagnostics.headingSummary", number(headingAccuracyDegrees),
                           number(headingAgeSeconds), number(headingResidualDegrees),
                           number(gravityAlignmentErrorDegrees), L10n.string(magneticKey))
    }

    var directionHardwareAvailable: Bool {
        motionManager.isDeviceMotionAvailable && CLLocationManager.headingAvailable()
    }

    var movementSafetyStatus: MovementSafetyStatus {
        guard CMMotionActivityManager.isActivityAvailable() else { return .unavailable }
        switch CMMotionActivityManager.authorizationStatus() {
        case .authorized:
            return hasStationaryConfirmation ? .ready : .awaitingStationaryConfirmation
        case .notDetermined:
            return .awaitingAuthorization
        case .denied, .restricted:
            return .denied
        @unknown default:
            return .denied
        }
    }

    var effectiveHeadingAccuracyDegrees: Double? {
        guard headingIsFresh,
              let headingAccuracyDegrees,
              headingAccuracyDegrees.isFinite,
              headingAccuracyDegrees >= 0,
              referenceKind != .arbitrary else { return nil }
        if referenceKind == .magnetic && trueHeadingDegrees == nil { return nil }

        var conservative = headingAccuracyDegrees
        if let headingResidualDegrees { conservative = max(conservative, headingResidualDegrees) }
        if magneticAccuracy == .uncalibrated { conservative = max(conservative, 30.0) }
        if let gravityAlignmentErrorDegrees, gravityAlignmentErrorDegrees > 2.0 {
            conservative = max(conservative, 30.0)
        }
        return conservative
    }

    private func startDeviceMotion() {
        guard motionManager.isDeviceMotionAvailable else { return }

        let available = CMMotionManager.availableAttitudeReferenceFrames()
        let frame: CMAttitudeReferenceFrame
        if available.contains(.xTrueNorthZVertical) {
            frame = .xTrueNorthZVertical
            usesTrueNorthReference = true
            referenceKind = .trueNorth
        } else if available.contains(.xMagneticNorthZVertical) {
            frame = .xMagneticNorthZVertical
            usesTrueNorthReference = false
            referenceKind = .magnetic
        } else {
            frame = .xArbitraryCorrectedZVertical
            usesTrueNorthReference = false
            referenceKind = .arbitrary
        }

        motionManager.deviceMotionUpdateInterval = 1.0 / 30.0
        let generation = sensorGeneration
        motionManager.startDeviceMotionUpdates(using: frame, to: motionQueue) { [weak self] motion, _ in
            guard let self, let motion else { return }
            Task { @MainActor in
                guard self.isRunning, self.sensorGeneration == generation else { return }
                self.consume(motion)
            }
        }
    }

    private func startActivityMonitoring() {
        hasStationaryConfirmation = false
        guard CMMotionActivityManager.isActivityAvailable() else {
            isUnsafeMotion = false
            return
        }
        let generation = sensorGeneration
        activityManager.startActivityUpdates(to: motionQueue) { [weak self] activity in
            guard let self, let activity else { return }
            let unsafe = activity.walking || activity.running || activity.cycling || activity.automotive
            let stationary = !unsafe
                && activity.stationary
                && activity.confidence != .low
            Task { @MainActor in
                guard self.isRunning, self.sensorGeneration == generation else { return }
                self.isUnsafeMotion = unsafe
                self.hasStationaryConfirmation = stationary
            }
        }
    }

    private func consume(_ motion: CMDeviceMotion) {
        // Freshness must use the measurement time, not a delayed main-queue delivery.
        let age = ProcessInfo.processInfo.systemUptime - motion.timestamp
        guard age >= 0, age <= 0.25 else { return }
        guard lastMotionUptime.map({ motion.timestamp > $0 }) ?? true else { return }
        let raw = Matrix3(motion.attitude.rotationMatrix)
        let gravity = Vector3(motion.gravity)
        let worldDown = Vector3(x: 0, y: 0, z: -1)

        // Apple's matrix convention is isolated here. Select the orientation that
        // satisfies the measurable invariant R × worldDown ≈ deviceGravity.
        let referenceToDevice = raw
        let predictedGravity = (referenceToDevice * worldDown).normalized
        let measuredGravity = gravity.normalized
        gravityAlignmentErrorDegrees = Vector3.angleDegrees(predictedGravity, measuredGravity)
        let deviceToReference = referenceToDevice.transposed

        // The rear camera looks along device -Z.
        let cameraInReference = (deviceToReference * Vector3(x: 0, y: 0, z: -1)).normalized
        let horizontalLength = hypot(cameraInReference.x, cameraInReference.y)

        var azimuth = lastStableAzimuth ?? 0.0
        if horizontalLength > 0.015 {
            // x = north, y = west, z = up in the chosen Core Motion reference frame.
            azimuth = AngleMath.normalizeDegrees(
                AngleMath.degrees(atan2(-cameraInReference.y, cameraInReference.x))
            )

            if referenceKind == .magnetic,
               let trueHeadingDegrees,
               let magnetic = magneticHeadingDegrees {
                azimuth = AngleMath.normalizeDegrees(azimuth + trueHeadingDegrees - magnetic)
            }
            lastStableAzimuth = azimuth
        }

        let altitude = AngleMath.degrees(
            asin(AngleMath.clamp(cameraInReference.z, min: -1.0, max: 1.0))
        )
        aim = DeviceAim(azimuthDegrees: azimuth, altitudeDegrees: altitude)
        lastMotionAt = Date()
        lastMotionUptime = motion.timestamp
        magneticAccuracy = motion.magneticField.accuracy

        let topInReference = (deviceToReference * Vector3(x: 0, y: 1, z: 0)).normalized
        let predicted: Double?
        if hypot(topInReference.x, topInReference.y) > 0.3 {
            predicted = AngleMath.normalizeDegrees(
                AngleMath.degrees(atan2(-topInReference.y, topInReference.x))
            )
        } else {
            predicted = nil
        }
        headingPairing.record(headingDegrees: predicted, at: motion.timestamp)
        refreshPairedHeadingResidual()
    }

    private func refreshPairedHeadingResidual() {
        guard headingIsFresh, let lastHeadingUptime, let trueHeadingDegrees else {
            headingResidualDegrees = nil
            return
        }
        // A compass event is compared with motion at its own measurement time,
        // not with the latest pose after the user has already turned the phone.
        let headingInReference = AngleMath.normalizeDegrees(trueHeadingDegrees - headingReferenceOffsetDegrees)
        headingResidualDegrees = headingPairing.residual(headingDegrees: headingInReference,
                                                       at: lastHeadingUptime)
    }
}

extension SensorService: CLLocationManagerDelegate {
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        locationServicesAreEnabled = CLLocationManager.locationServicesEnabled()
        authorizationStatus = manager.authorizationStatus
        let status = manager.authorizationStatus
        let isAuthorized = status == .authorizedAlways || status == .authorizedWhenInUse
        if wantsLocationUpdates, isRunning, isAuthorized {
            manager.startUpdatingLocation()
        }
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard isRunning, wantsLocationUpdates, let candidate = locations.last,
              candidate.timestamp >= sessionStartedAt.addingTimeInterval(-2),
              candidate.horizontalAccuracy >= 0,
              abs(candidate.timestamp.timeIntervalSinceNow) < 60 else { return }
        location = candidate
    }

    func locationManager(_ manager: CLLocationManager, didUpdateHeading newHeading: CLHeading) {
        guard isRunning,
              newHeading.timestamp >= sessionStartedAt.addingTimeInterval(-2),
              abs(newHeading.timestamp.timeIntervalSinceNow) <= 5 else { return }
        guard lastHeadingAt.map({ newHeading.timestamp >= $0 }) ?? true else { return }
        let uptime = ProcessInfo.processInfo.systemUptime + newHeading.timestamp.timeIntervalSinceNow
        guard uptime <= ProcessInfo.processInfo.systemUptime else { return }
        headingAccuracyDegrees = newHeading.headingAccuracy >= 0 ? newHeading.headingAccuracy : nil
        trueHeadingDegrees = newHeading.trueHeading >= 0 ? newHeading.trueHeading : nil
        magneticHeadingDegrees = newHeading.magneticHeading >= 0 ? newHeading.magneticHeading : nil
        lastHeadingAt = newHeading.timestamp
        lastHeadingUptime = uptime
        headingReferenceOffsetDegrees = referenceKind == .magnetic
            ? (trueHeadingDegrees ?? 0) - (magneticHeadingDegrees ?? 0) : 0
        refreshPairedHeadingResidual()
    }

    func locationManagerShouldDisplayHeadingCalibration(_ manager: CLLocationManager) -> Bool {
        headingAccuracyDegrees.map { $0 > 10.0 } ?? true
    }
}

private struct Vector3 {
    let x: Double
    let y: Double
    let z: Double

    init(x: Double, y: Double, z: Double) {
        self.x = x
        self.y = y
        self.z = z
    }

    init(_ gravity: CMAcceleration) {
        self.init(x: gravity.x, y: gravity.y, z: gravity.z)
    }

    static func - (lhs: Self, rhs: Self) -> Self {
        .init(x: lhs.x - rhs.x, y: lhs.y - rhs.y, z: lhs.z - rhs.z)
    }

    var length: Double { sqrt(x * x + y * y + z * z) }

    var normalized: Self {
        let divisor = max(length, 1e-12)
        return .init(x: x / divisor, y: y / divisor, z: z / divisor)
    }

    static func angleDegrees(_ lhs: Self, _ rhs: Self) -> Double {
        let dot = lhs.x * rhs.x + lhs.y * rhs.y + lhs.z * rhs.z
        let crossX = lhs.y * rhs.z - lhs.z * rhs.y
        let crossY = lhs.z * rhs.x - lhs.x * rhs.z
        let crossZ = lhs.x * rhs.y - lhs.y * rhs.x
        let crossLength = sqrt(crossX * crossX + crossY * crossY + crossZ * crossZ)
        return AngleMath.degrees(atan2(crossLength, dot))
    }
}

private enum ReferenceKind {
    case trueNorth
    case magnetic
    case arbitrary
}

private struct Matrix3 {
    let m11: Double; let m12: Double; let m13: Double
    let m21: Double; let m22: Double; let m23: Double
    let m31: Double; let m32: Double; let m33: Double

    init(_ matrix: CMRotationMatrix) {
        m11 = matrix.m11; m12 = matrix.m12; m13 = matrix.m13
        m21 = matrix.m21; m22 = matrix.m22; m23 = matrix.m23
        m31 = matrix.m31; m32 = matrix.m32; m33 = matrix.m33
    }

    private init(
        _ m11: Double, _ m12: Double, _ m13: Double,
        _ m21: Double, _ m22: Double, _ m23: Double,
        _ m31: Double, _ m32: Double, _ m33: Double
    ) {
        self.m11 = m11; self.m12 = m12; self.m13 = m13
        self.m21 = m21; self.m22 = m22; self.m23 = m23
        self.m31 = m31; self.m32 = m32; self.m33 = m33
    }

    var transposed: Self {
        .init(m11, m21, m31, m12, m22, m32, m13, m23, m33)
    }

    static func * (lhs: Self, rhs: Vector3) -> Vector3 {
        .init(
            x: lhs.m11 * rhs.x + lhs.m12 * rhs.y + lhs.m13 * rhs.z,
            y: lhs.m21 * rhs.x + lhs.m22 * rhs.y + lhs.m23 * rhs.z,
            z: lhs.m31 * rhs.x + lhs.m32 * rhs.y + lhs.m33 * rhs.z
        )
    }
}
