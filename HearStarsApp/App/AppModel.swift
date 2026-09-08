import Combine
import CoreLocation
import Foundation
import HearStarsCore
import UIKit

@MainActor
final class AppModel: ObservableObject {
    @Published var route: AppRoute = .picker
    @Published var guidanceMode: GuidanceMode = .sound
    @Published var selectedStarID: String = StarCatalog.prototype[0].id
    @Published var isPractice = false
    @Published var simulatorEnabled = false
    @Published private(set) var observations: [String: HorizontalCoordinate] = [:]
    @Published private(set) var guidance: GuidanceState?
    @Published private(set) var directionReadiness: DirectionReadiness = .locating
    @Published private(set) var simulatedAim = DeviceAim(azimuthDegrees: 0, altitudeDegrees: 20)

    let sensors = SensorService()
    let stars = StarCatalog.prototype

    private let audio = AudioGuideEngine()
    private let haptics = HapticGuideEngine()
    private var timer: Timer?
    private var holdTracker = DiscoveryHoldTracker(requiredDuration: 0.8)
    private var nextPulseAt = Date.distantPast
    private var lastAnnouncedBand: GuidanceBand?
    private var lastAnnouncedDirection: DirectionCue?
    private var lastAnnouncementAt = Date.distantPast
    private var wasPausedForMotion = false
    private var preparationStartedAt = ProcessInfo.processInfo.systemUptime

    private static let practiceObserver = ObserverLocation(
        latitudeDegrees: 35.6812,
        longitudeDegrees: 139.7671
    )

    private static let practiceDate: Date = {
        var components = DateComponents()
        components.calendar = Calendar(identifier: .gregorian)
        components.timeZone = TimeZone(secondsFromGMT: 0)
        components.year = 2026
        components.month = 1
        components.day = 15
        components.hour = 12
        return components.date ?? Date(timeIntervalSince1970: 1_768_478_400)
    }()

    var selectedStar: Star {
        stars.first(where: { $0.id == selectedStarID }) ?? stars[0]
    }

    var selectedObservation: HorizontalCoordinate? {
        observations[selectedStarID]
    }

    var isUsingSimulatedAim: Bool {
        isPractice && simulatorEnabled
    }

    var hasUsableLiveLocation: Bool {
        guard sensors.location != nil else { return false }
        switch sensors.authorizationStatus {
        case .authorizedAlways, .authorizedWhenInUse:
            return true
        default:
            return false
        }
    }

    var observationDate: Date {
        isPractice ? Self.practiceDate : Date()
    }

    var observerDescription: String {
        if isPractice { return L10n.string("location.practiceTokyo") }
        if hasUsableLiveLocation { return L10n.string("location.current") }
        return L10n.string("location.waiting")
    }

    func start() {
        guard timer == nil else { return }
        refresh()
        let timer = Timer(timeInterval: 0.1, repeats: true) { [weak self] _ in
            Task { @MainActor in self?.refresh() }
        }
        RunLoop.main.add(timer, forMode: .common)
        self.timer = timer
    }

    func stop() {
        timer?.invalidate()
        timer = nil
        sensors.stop()
        audio.stop()
        haptics.shutdown()
    }

    func enterBackground() {
        sensors.stop()
        audio.stop()
        haptics.shutdown()
        guidance = nil
        holdTracker.reset()
        directionReadiness = .checkingDirection
    }

    func becomeActive() {
        if route == .calibration || route == .finder || route == .constellation {
            preparationStartedAt = ProcessInfo.processInfo.systemUptime
            sensors.start(requestLocation: !isPractice)
            refresh()
        }
    }

    func setPractice(_ enabled: Bool) {
        isPractice = enabled
        simulatorEnabled = enabled
        refresh()
    }

    func select(_ star: Star) {
        selectedStarID = star.id
        refresh()
    }

    func startFinding(_ star: Star) {
        stopPulses()
        isPractice = false
        simulatorEnabled = false
        selectedStarID = star.id
        holdTracker.reset()
        nextPulseAt = .distantPast
        lastAnnouncedBand = nil
        lastAnnouncedDirection = nil
        preparationStartedAt = ProcessInfo.processInfo.systemUptime
        directionReadiness = .checkingDirection
        sensors.start(requestLocation: true)
        route = .finder
        refresh()
    }

    func showSafety() {
        if selectedObservation?.isAboveGeometricHorizon == false && !isPractice {
            enablePracticeFallback(announcementKey: "finder.belowHorizonFallback")
        }
        route = .safety
    }

    func confirmStoppedAndSafe() {
        sensors.start(requestLocation: !isPractice)
        route = .calibration
    }

    func enterFinder() {
        if let target = selectedObservation,
           !isPractice,
           !target.isAboveGeometricHorizon {
            enablePracticeFallback(announcementKey: "finder.belowHorizonFallback")
            refreshObservations()
        }

        guard let target = selectedObservation else {
            route = .finder
            return
        }
        simulatedAim = DeviceAim(
            azimuthDegrees: target.azimuthDegrees - 45.0,
            altitudeDegrees: target.altitudeDegrees - 15.0
        )
        holdTracker.reset()
        nextPulseAt = .distantPast
        lastAnnouncedBand = nil
        lastAnnouncedDirection = nil
        route = .finder
    }

    func returnToPicker() {
        sensors.stop()
        audio.stop()
        haptics.stop()
        guidance = nil
        holdTracker.reset()
        wasPausedForMotion = false
        route = .picker
    }

    func restartFinding() {
        sensors.stop()
        startFinding(selectedStar)
    }

    func retryDirectionSetup() {
        stopPulses()
        holdTracker.reset()
        preparationStartedAt = ProcessInfo.processInfo.systemUptime
        directionReadiness = .checkingDirection
        sensors.stop()
        sensors.start(requestLocation: !isPractice)
        refresh()
    }

    func openAppSettings() {
        guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
        UIApplication.shared.open(url)
    }

    func chooseMode(_ mode: GuidanceMode) {
        guidanceMode = mode
        audio.stop()
        haptics.stop()
        nextPulseAt = .distantPast
    }

    func setSimulatorEnabled(_ enabled: Bool) {
        simulatorEnabled = enabled
        if isPractice && !enabled {
            // Device-based practice needs true north. Location is used only for
            // that reference; the practice sky remains the fixed fixture.
            sensors.start(requestLocation: true)
        }
        holdTracker.reset()
        nextPulseAt = .distantPast
    }

    func nudgeSimulatedAim(azimuth: Double, altitude: Double) {
        simulatedAim = DeviceAim(
            azimuthDegrees: simulatedAim.azimuthDegrees + azimuth,
            altitudeDegrees: simulatedAim.altitudeDegrees + altitude
        )
        holdTracker.reset()
    }

    func findAnotherStar() {
        returnToPicker()
    }

    func showConstellation() {
        stopPulses()
        preparationStartedAt = ProcessInfo.processInfo.systemUptime
        directionReadiness = .checkingDirection
        sensors.start(requestLocation: !isPractice)
        route = .constellation
        refresh()
    }

    func returnToDiscovery() {
        sensors.stop()
        stopPulses()
        guidance = nil
        holdTracker.reset()
        route = .discovery
    }

    func usePracticeFallback() {
        enablePracticeFallback(announcementKey: "finder.practiceFallbackActivated")
        refreshObservations()
        enterFinder()
    }

    private func refresh() {
        refreshObservations()
        if route == .finder || route == .constellation {
            refreshDirectionReadiness()
        }
        guard route == .finder else {
            guidance = nil
            return
        }

        guard let target = selectedObservation else {
            guidance = nil
            stopPulses()
            holdTracker.reset()
            return
        }

        guard directionReadiness.canUseDirection else {
            guidance = nil
            stopPulses()
            holdTracker.reset()
            return
        }

        if sensors.isUnsafeMotion {
            guidance = nil
            if !wasPausedForMotion {
                announce(L10n.string("finder.pausedMoving"), force: true)
            }
            wasPausedForMotion = true
            stopPulses()
            holdTracker.reset()
            return
        }
        wasPausedForMotion = false

        let aim: DeviceAim?
        let sensorIsFresh: Bool
        let headingAccuracy: Double?
        if isUsingSimulatedAim {
            aim = simulatedAim
            sensorIsFresh = true
            headingAccuracy = 0
        } else {
            aim = sensors.aim
            sensorIsFresh = sensors.motionIsFresh
            headingAccuracy = sensors.effectiveHeadingAccuracyDegrees
        }

        guard let aim else {
            guidance = nil
            stopPulses()
            holdTracker.reset()
            return
        }

        let state = GuidanceMapper.map(
            GuidanceInput(
                target: target,
                aim: aim,
                headingAccuracyDegrees: headingAccuracy,
                isMoving: sensors.isUnsafeMotion,
                isSensorFresh: sensorIsFresh,
                isPractice: isPractice
            )
        )
        guard state.canGuide else {
            guidance = nil
            stopPulses()
            holdTracker.reset()
            return
        }

        guidance = state

        announceBandIfNeeded(state)
        emitPulseIfNeeded(state)

        if holdTracker.update(isEligible: state.canDiscover, at: Date()) {
            completeDiscovery()
        }
    }

    private func refreshObservations() {
        let observer: ObserverLocation?
        if isPractice {
            observer = Self.practiceObserver
        } else if hasUsableLiveLocation,
                  let coordinate = sensors.location?.coordinate {
            observer = ObserverLocation(
                latitudeDegrees: coordinate.latitude,
                longitudeDegrees: coordinate.longitude
            )
        } else {
            observer = nil
        }

        guard let observer else {
            observations = [:]
            return
        }
        let date = observationDate
        observations = Dictionary(uniqueKeysWithValues: stars.map { star in
            (star.id, AstronomyCalculator.horizontalCoordinate(for: star, at: date, observer: observer))
        })
    }

    private func refreshDirectionReadiness() {
        let location: DirectionReadiness.LocationState
        if isPractice {
            location = .available
        } else {
            switch sensors.authorizationStatus {
            case .notDetermined: location = .permissionRequired
            case .denied:
                location = sensors.locationServicesAreEnabled ? .denied : .servicesOff
            case .restricted: location = .restricted
            case .authorizedAlways, .authorizedWhenInUse:
                location = hasUsableLiveLocation ? .available : .waiting
            @unknown default: location = .restricted
            }
        }
        let state = DirectionReadiness.evaluate(
            location: location,
            directionHardwareAvailable: isUsingSimulatedAim || sensors.directionHardwareAvailable,
            sensorIsFresh: isUsingSimulatedAim || (sensors.motionIsFresh && sensors.aim != nil),
            headingAccuracyDegrees: isUsingSimulatedAim ? 0 : sensors.effectiveHeadingAccuracyDegrees,
            targetAltitudeDegrees: selectedObservation?.altitudeDegrees,
            isMoving: sensors.isUnsafeMotion,
            preparationHasTimedOut: ProcessInfo.processInfo.systemUptime - preparationStartedAt >= 12
        )
        guard state != directionReadiness else { return }
        directionReadiness = state
        announce(L10n.string(state.titleLocalizationKey), force: false)
    }

    private func emitPulseIfNeeded(_ state: GuidanceState) {
        let now = Date()
        guard now >= nextPulseAt else { return }
        nextPulseAt = now.addingTimeInterval(state.pulseIntervalSeconds)

        audio.playGuidancePulse(
            for: selectedStar,
            azimuthError: state.azimuthErrorDegrees,
            altitudeError: state.altitudeErrorDegrees,
            clarity: state.clarity
        )
        haptics.playGuidancePulse(clarity: state.clarity)
    }

    private func stopPulses() {
        audio.stop()
        haptics.stop()
        nextPulseAt = .distantPast
        lastAnnouncedBand = nil
        lastAnnouncedDirection = nil
    }

    private func completeDiscovery() {
        audio.stop()
        haptics.stop()
        audio.playDiscovery(for: selectedStar)
        haptics.playDiscovery(for: selectedStar)
        sensors.stop()
        announce(
            L10n.string("discovery.title"),
            force: true
        )
        route = .discovery
    }

    private func announceBandIfNeeded(_ state: GuidanceState) {
        guard state.band != lastAnnouncedBand
                || state.direction != lastAnnouncedDirection else { return }
        let now = Date()
        guard now.timeIntervalSince(lastAnnouncementAt) >= 2.0 else { return }
        lastAnnouncedBand = state.band
        lastAnnouncedDirection = state.direction
        lastAnnouncementAt = now
        announce(directionDescription(state), force: false)
    }

    private func enablePracticeFallback(announcementKey: String) {
        stopPulses()
        guidance = nil
        isPractice = true
        simulatorEnabled = true
        holdTracker.reset()
        nextPulseAt = .distantPast
        announce(L10n.string(announcementKey), force: true)
    }

    func directionDescription(_ state: GuidanceState) -> String {
        let direction = L10n.string("direction.\(state.direction.rawValue)")
        let horizontal = abs(state.azimuthErrorDegrees)
        let vertical = abs(state.altitudeErrorDegrees)
        return L10n.format("finder.voiceStatus", direction, horizontal, vertical)
    }

    private func announce(_ message: String, force: Bool) {
        guard force || UIAccessibility.isVoiceOverRunning else { return }
        UIAccessibility.post(notification: .announcement, argument: message)
    }
}
