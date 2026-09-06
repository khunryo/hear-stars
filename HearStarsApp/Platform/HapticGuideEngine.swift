import CoreHaptics
import HearStarsCore
import UIKit

@MainActor
final class HapticGuideEngine {
    private var engine: CHHapticEngine?
    private var activePlayers: [CHHapticPatternPlayer] = []
    private let fallback = UIImpactFeedbackGenerator(style: .soft)

    func prepare() {
        fallback.prepare()
        guard CHHapticEngine.capabilitiesForHardware().supportsHaptics else { return }
        if engine == nil {
            engine = try? CHHapticEngine()
            engine?.stoppedHandler = { _ in }
            engine?.resetHandler = { [weak self] in
                Task { @MainActor [weak self] in
                    try? self?.engine?.start()
                }
            }
        }
        try? engine?.start()
    }

    func playGuidancePulse(clarity: Double) {
        prepare()
        stopActivePlayers()
        guard let engine else {
            fallback.impactOccurred(intensity: CGFloat(0.35 + clarity * 0.45))
            return
        }
        let event = CHHapticEvent(
            eventType: .hapticTransient,
            parameters: [
                .init(parameterID: .hapticIntensity, value: Float(0.28 + clarity * 0.58)),
                .init(parameterID: .hapticSharpness, value: Float(0.18 + clarity * 0.58))
            ],
            relativeTime: 0
        )
        guard let pattern = try? CHHapticPattern(events: [event], parameters: []),
              let player = try? engine.makePlayer(with: pattern) else { return }
        activePlayers = [player]
        try? player.start(atTime: 0)
    }

    func playDiscovery(for star: Star) {
        prepare()
        stopActivePlayers()
        guard let engine else {
            fallback.impactOccurred(intensity: 0.9)
            return
        }

        var cursor = 0.0
        let events = star.discoveryPattern.hapticDurations.map { duration -> CHHapticEvent in
            defer { cursor += duration + 0.07 }
            return CHHapticEvent(
                eventType: .hapticContinuous,
                parameters: [
                    .init(parameterID: .hapticIntensity, value: 0.82),
                    .init(parameterID: .hapticSharpness, value: 0.48)
                ],
                relativeTime: cursor,
                duration: duration
            )
        }
        guard let pattern = try? CHHapticPattern(events: events, parameters: []),
              let player = try? engine.makePlayer(with: pattern) else { return }
        activePlayers = [player]
        try? player.start(atTime: 0)
    }

    func stop() {
        // Keep the idle engine warm so an immediate discovery pattern cannot
        // race an asynchronous engine shutdown.
        stopActivePlayers()
    }

    func shutdown() {
        stopActivePlayers()
        engine?.stop(completionHandler: nil)
    }

    private func stopActivePlayers() {
        for player in activePlayers {
            try? player.stop(atTime: 0)
        }
        activePlayers.removeAll(keepingCapacity: true)
    }
}
