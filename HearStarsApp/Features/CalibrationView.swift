import HearStarsCore
import SwiftUI

struct CalibrationView: View {
    @ObservedObject var model: AppModel
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    private var displayedAccuracy: Double? {
        model.isUsingSimulatedAim ? 0 : model.sensors.effectiveHeadingAccuracyDegrees
    }

    private var quality: HeadingQuality {
        GuidanceMapper.headingQuality(displayedAccuracy)
    }

    var body: some View {
        GeometryReader { geometry in
            ViewThatFits {
                if !dynamicTypeSize.isAccessibilitySize && geometry.size.height >= 700 {
                    regularContent
                        .padding(20)
                } else {
                    compactContent
                        .padding(14)
                }

                compactContent
                    .padding(14)

                minimumContent
                    .padding(12)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }

    private var regularContent: some View {
        VStack(spacing: 16) {
            header

            Spacer(minLength: 4)

            FigureEightView(animated: !reduceMotion)
                .frame(maxWidth: 260, maxHeight: 220)
                .accessibilityHidden(true)

            Text("calibration.title")
                .font(.title2.weight(.medium))
                .multilineTextAlignment(.center)
            Text("calibration.body")
                .font(.body)
                .foregroundStyle(Color.hsSecondary)
                .multilineTextAlignment(.center)

            Text("calibration.interference")
                .font(.caption)
                .foregroundStyle(Color.hsGuide)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
                .padding(14)
                .frame(maxWidth: .infinity)
                .nightPanel()

            if shouldOfferPracticeFallback {
                fallbackPanel(compact: false)
            }

            Spacer(minLength: 4)

            continueButton
        }
    }

    private var compactContent: some View {
        VStack(spacing: 7) {
            header

            Spacer(minLength: 0)

            Text("calibration.title")
                .font(.headline)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)

            Text("calibration.compactBody")
                .font(.caption)
                .foregroundStyle(Color.hsSecondary)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)

            if shouldOfferPracticeFallback {
                fallbackPanel(compact: true)
            }

            Spacer(minLength: 0)

            continueButton
        }
    }

    @ViewBuilder
    private var minimumContent: some View {
        VStack(spacing: 8) {
            minimumHeader

            Spacer(minLength: 0)

            if shouldOfferPracticeFallback {
                Text(minimumFallbackReasonKey)
                    .font(.caption)
                    .foregroundStyle(Color.hsSecondary)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)

                fallbackButton(compact: true)
            } else {
                Text("calibration.compactBody")
                    .font(.caption)
                    .foregroundStyle(Color.hsSecondary)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)

                continueButton
            }

            Spacer(minLength: 0)
        }
    }

    private var header: some View {
        HStack {
            Button(action: model.returnToPicker) {
                Image(systemName: "xmark")
                    .frame(width: 44, height: 44)
            }
            .accessibilityLabel(Text("common.close"))
            Spacer()
            AccuracyPill(accuracy: displayedAccuracy)
        }
    }

    private var minimumHeader: some View {
        HStack {
            Button(action: model.returnToPicker) {
                Image(systemName: "xmark")
                    .frame(width: 44, height: 44)
            }
            .accessibilityLabel(Text("common.close"))
            Spacer()
        }
    }

    private var shouldOfferPracticeFallback: Bool {
        guard !model.isPractice,
              !model.sensors.isUnsafeMotion else { return false }
        return model.sensors.movementSafetyStatus != .ready
            || !model.hasUsableLiveLocation
            || !model.sensors.motionIsFresh
            || quality == .unavailable
    }

    private func fallbackPanel(compact: Bool) -> some View {
        VStack(spacing: 6) {
            Text(fallbackReasonKey(compact: compact))
                .font(compact ? .caption2 : .caption)
                .foregroundStyle(Color.hsSecondary)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)

            fallbackButton(compact: compact)
        }
        .padding(.horizontal, 10)
        .nightPanel()
    }

    private func fallbackReasonKey(compact: Bool) -> LocalizedStringKey {
        if let movementSafetyKey = movementSafetyReasonKey(compact: compact) {
            return movementSafetyKey
        }
        if !model.hasUsableLiveLocation {
            return compact
                ? "calibration.compactLocationUnavailable"
                : "calibration.locationUnavailable"
        }
        if !model.sensors.motionIsFresh {
            return compact
                ? "finder.waitingSensors"
                : "calibration.sensorsUnavailable"
        }
        return compact
            ? "calibration.compactHeadingUnavailable"
            : "calibration.headingUnavailable"
    }

    private var minimumFallbackReasonKey: LocalizedStringKey {
        fallbackReasonKey(compact: true)
    }

    private func movementSafetyReasonKey(compact: Bool) -> LocalizedStringKey? {
        switch model.sensors.movementSafetyStatus {
        case .ready:
            return nil
        case .unavailable:
            return compact
                ? "finder.activityUnavailable"
                : "calibration.activityUnavailable"
        case .awaitingAuthorization:
            return compact
                ? "finder.waitingActivityAuthorization"
                : "calibration.waitingActivityAuthorization"
        case .awaitingStationaryConfirmation:
            return compact
                ? "finder.waitingStationaryConfirmation"
                : "calibration.waitingStationaryConfirmation"
        case .denied:
            return compact
                ? "finder.activityDenied"
                : "calibration.activityDenied"
        }
    }

    private func fallbackButton(compact: Bool) -> some View {
        Button(action: model.usePracticeFallback) {
            Label("finder.usePracticeFallback", systemImage: "hand.tap")
                .font(compact ? .caption.weight(.medium) : .subheadline.weight(.medium))
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity, minHeight: 44)
        }
        .buttonStyle(.plain)
        .foregroundStyle(Color.hsDiscovery)
        .accessibilityHint(Text("finder.usePracticeFallbackHint"))
    }

    private var continueButton: some View {
        Button(action: model.enterFinder) {
            Text(LocalizedStringKey(
                quality == .good || quality == .fair
                    ? "calibration.continue"
                    : "calibration.continueLimited"
            ))
                .font(.headline)
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity, minHeight: 52)
                .background(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .fill((quality == .good || quality == .fair ? Color.hsDiscovery : Color.hsGuide).opacity(0.9))
                )
                .foregroundStyle(Color.hsNight)
        }
        .buttonStyle(.plain)
    }
}

private struct FigureEightView: View {
    let animated: Bool

    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 20.0, paused: !animated)) { timeline in
            Canvas { context, size in
                let rect = CGRect(origin: .zero, size: size).insetBy(dx: 18, dy: 18)
                var path = Path()
                let samples = 120
                for index in 0...samples {
                    let t = Double(index) / Double(samples) * Double.pi * 2
                    let point = CGPoint(
                        x: rect.midX + CGFloat(sin(t)) * rect.width * 0.42,
                        y: rect.midY + CGFloat(sin(t * 2)) * rect.height * 0.32
                    )
                    index == 0 ? path.move(to: point) : path.addLine(to: point)
                }
                context.stroke(path, with: .color(.hsSecondary.opacity(0.6)), lineWidth: 0.8)

                let phase = animated
                    ? timeline.date.timeIntervalSinceReferenceDate.truncatingRemainder(dividingBy: 4) / 4
                    : 0.18
                let t = phase * Double.pi * 2
                let dot = CGPoint(
                    x: rect.midX + CGFloat(sin(t)) * rect.width * 0.42,
                    y: rect.midY + CGFloat(sin(t * 2)) * rect.height * 0.32
                )
                context.fill(Path(ellipseIn: CGRect(x: dot.x - 4, y: dot.y - 4, width: 8, height: 8)), with: .color(.hsDiscovery))
            }
        }
    }
}
