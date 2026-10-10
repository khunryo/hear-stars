import AVFoundation
import Combine
import Foundation

struct CameraPreviewMetrics: Sendable {
    let landscapeFieldOfView: Double
    let landscapeAspectRatio: Double
}

/// The serial worker owns capture configuration/start/stop; never records frames.
private final class CameraPreviewWorker: @unchecked Sendable {
    let session = AVCaptureSession()
    private let queue = DispatchQueue(label: "HearStars.camera-preview", qos: .userInitiated)
    private var metrics: CameraPreviewMetrics?

    func start(completion: @escaping @Sendable (CameraPreviewMetrics?) -> Void) {
        queue.async { [self] in
            if metrics == nil {
                guard let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back),
                      let input = try? AVCaptureDeviceInput(device: device) else { completion(nil); return }
                session.beginConfiguration()
                // Failed configuration may be retried without duplicate inputs.
                session.inputs.forEach { session.removeInput($0) }
                if session.canSetSessionPreset(.hd1280x720) { session.sessionPreset = .hd1280x720 }
                guard session.canAddInput(input) else { session.commitConfiguration(); completion(nil); return }
                session.addInput(input)
                session.commitConfiguration()
                do {
                    try device.lockForConfiguration()
                    device.videoZoomFactor = 1
                    if device.isGeometricDistortionCorrectionSupported { device.isGeometricDistortionCorrectionEnabled = false }
                    device.unlockForConfiguration()
                } catch { completion(nil); return }
                let dimensions = CMVideoFormatDescriptionGetDimensions(device.activeFormat.formatDescription)
                let fov = Double(device.activeFormat.videoFieldOfView)
                guard dimensions.width > 0, dimensions.height > 0, fov > 0 else { completion(nil); return }
                metrics = .init(landscapeFieldOfView: fov,
                    landscapeAspectRatio: Double(dimensions.width) / Double(dimensions.height))
            }
            if !session.isRunning { session.startRunning() }
            completion(session.isRunning && !session.isInterrupted ? metrics : nil)
        }
    }
    func stop() { queue.async { [self] in if session.isRunning { session.stopRunning() } } }
}

@MainActor
final class CameraPreviewService: ObservableObject {
    enum State { case off, requesting, running, denied, unavailable, interrupted }
    @Published private(set) var state: State = .off
    @Published private(set) var metrics: CameraPreviewMetrics?
    private let worker = CameraPreviewWorker()
    private var generation = 0
    private var observers: [NSObjectProtocol] = []
    var session: AVCaptureSession { worker.session }

    init() {
        for name in [AVCaptureSession.wasInterruptedNotification, AVCaptureSession.runtimeErrorNotification] {
            observers.append(NotificationCenter.default.addObserver(forName: name, object: worker.session, queue: .main) { [weak self] _ in
                Task { @MainActor in
                    guard let self, self.state != .off else { return }
                    self.stop()
                    self.state = .interrupted
                }
            })
        }
    }
    deinit {
        observers.forEach(NotificationCenter.default.removeObserver)
        worker.stop()
    }
    func start() async {
        generation += 1
        let ticket = generation
        state = .requesting
        var authorized = AVCaptureDevice.authorizationStatus(for: .video) == .authorized
        if AVCaptureDevice.authorizationStatus(for: .video) == .notDetermined {
            authorized = await AVCaptureDevice.requestAccess(for: .video)
        }
        guard generation == ticket else { return }
        guard authorized else { state = .denied; return }
        worker.start { [weak self] metrics in
            Task { @MainActor in
                guard let self, self.generation == ticket else { return }
                self.metrics = metrics
                self.state = metrics == nil ? .unavailable : .running
            }
        }
    }
    func stop() {
        generation += 1
        state = .off
        metrics = nil
        worker.stop()
    }
}
