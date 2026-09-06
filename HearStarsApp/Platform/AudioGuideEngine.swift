import AVFoundation
import Foundation
import HearStarsCore

@MainActor
final class AudioGuideEngine {
    private let engine = AVAudioEngine()
    private let player = AVAudioPlayerNode()
    private let environment = AVAudioEnvironmentNode()
    private let sampleRate = 44_100.0
    private var isGraphConfigured = false
    private var isPrepared = false

    func prepare() {
        guard !isPrepared else { return }
        do {
            let session = AVAudioSession.sharedInstance()
            // The ambient category already mixes with other audio. Passing the
            // playback-only mixWithOthers option here can make setCategory fail.
            try session.setCategory(.ambient, mode: .default, options: [])
            try session.setActive(true)

            if !isGraphConfigured {
                guard let format = AVAudioFormat(
                    standardFormatWithSampleRate: sampleRate,
                    channels: 1
                ) else { return }

                engine.attach(player)
                engine.attach(environment)
                engine.connect(player, to: environment, format: format)
                engine.connect(environment, to: engine.mainMixerNode, format: nil)
                player.renderingAlgorithm = .HRTF
                environment.outputVolume = 0.45
                isGraphConfigured = true
            }
            if !engine.isRunning { try engine.start() }
            if !player.isPlaying { player.play() }
            isPrepared = true
        } catch {
            isPrepared = false
        }
    }

    func playGuidancePulse(
        for star: Star,
        azimuthError: Double,
        altitudeError: Double,
        clarity: Double
    ) {
        prepare()
        guard isPrepared,
              let buffer = makePulseBuffer(
                star: star,
                altitudeError: altitudeError,
                clarity: clarity
              ) else { return }
        let azimuth = Float(AngleMath.radians(AngleMath.signedDegrees(azimuthError)))
        let elevation = Float(
            AngleMath.radians(AngleMath.clamp(altitudeError, min: -60, max: 60))
        )
        let radius: Float = 2.2
        let horizontal = cos(elevation) * radius
        player.position = AVAudio3DPoint(
            x: sin(azimuth) * horizontal,
            y: sin(elevation) * radius,
            z: -cos(azimuth) * horizontal
        )
        player.scheduleBuffer(buffer, completionHandler: nil)
    }

    func playDiscovery(for star: Star) {
        prepare()
        guard isPrepared, let buffer = makeDiscoveryBuffer(star: star) else { return }
        player.position = AVAudio3DPoint(x: 0, y: 0, z: -1)
        player.scheduleBuffer(buffer, completionHandler: nil)
    }

    func stop() {
        let shouldDeactivateSession = isPrepared || engine.isRunning
        player.stop()
        if engine.isRunning { engine.stop() }
        isPrepared = false
        if shouldDeactivateSession {
            try? AVAudioSession.sharedInstance().setActive(
                false,
                options: .notifyOthersOnDeactivation
            )
        }
    }

    private func makePulseBuffer(
        star: Star,
        altitudeError: Double,
        clarity: Double
    ) -> AVAudioPCMBuffer? {
        guard let format = AVAudioFormat(standardFormatWithSampleRate: sampleRate, channels: 1) else {
            return nil
        }
        let duration = 0.075
        let frames = AVAudioFrameCount(sampleRate * duration)
        guard let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frames),
              let samples = buffer.floatChannelData?[0] else { return nil }
        buffer.frameLength = frames

        let identitySeed = stableSeed(for: star.id)
        let identitySemitones = Double(identitySeed % 7)
        let verticalSemitones = AngleMath.clamp(altitudeError / 8.0, min: -5.0, max: 5.0)
        let base = 176.0 * pow(2.0, (identitySemitones + verticalSemitones) / 12.0)
        var seed = identitySeed
        for index in 0..<Int(frames) {
            let time = Double(index) / sampleRate
            let progress = time / duration
            let envelope = sin(Double.pi * progress) * min(progress * 8.0, 1.0)
            seed = 1_664_525 &* seed &+ 1_013_904_223
            let noise = Double(seed & 0xFFFF) / 32_767.5 - 1.0
            let pure = sin(2.0 * Double.pi * base * time)
            let harmonic = sin(2.0 * Double.pi * base * 2.01 * time) * 0.18
            let mixed = (pure + harmonic) * (0.35 + 0.65 * clarity)
                + noise * (1.0 - clarity) * 0.22
            samples[index] = Float(mixed * envelope * 0.24)
        }
        return buffer
    }

    /// Swift's `hashValue` is deliberately randomized between launches. This
    /// small FNV-1a seed keeps each star's timbre stable and works offline.
    private func stableSeed(for value: String) -> UInt32 {
        value.utf8.reduce(UInt32(2_166_136_261)) { partial, byte in
            (partial ^ UInt32(byte)) &* 16_777_619
        }
    }

    private func makeDiscoveryBuffer(star: Star) -> AVAudioPCMBuffer? {
        guard let format = AVAudioFormat(standardFormatWithSampleRate: sampleRate, channels: 1) else {
            return nil
        }
        let noteDuration = 0.13
        let gap = 0.035
        let total = Double(star.discoveryPattern.semitoneOffsets.count) * (noteDuration + gap)
        let frames = AVAudioFrameCount(sampleRate * total)
        guard let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frames),
              let samples = buffer.floatChannelData?[0] else { return nil }
        buffer.frameLength = frames

        for index in 0..<Int(frames) {
            let time = Double(index) / sampleRate
            let slot = Int(time / (noteDuration + gap))
            guard slot < star.discoveryPattern.semitoneOffsets.count else {
                samples[index] = 0
                continue
            }
            let localTime = time - Double(slot) * (noteDuration + gap)
            guard localTime < noteDuration else {
                samples[index] = 0
                continue
            }
            let progress = localTime / noteDuration
            let envelope = pow(sin(Double.pi * progress), 0.75)
            let semitones = Double(star.discoveryPattern.semitoneOffsets[slot])
            let frequency = 220.0 * pow(2.0, semitones / 12.0)
            let value = sin(2.0 * Double.pi * frequency * localTime)
                + 0.14 * sin(2.0 * Double.pi * frequency * 2.0 * localTime)
            samples[index] = Float(value * envelope * 0.22)
        }
        return buffer
    }
}
