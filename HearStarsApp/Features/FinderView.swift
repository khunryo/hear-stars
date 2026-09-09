import CoreLocation
import HearStarsCore
import SwiftUI

struct FinderView: View {
    @ObservedObject var model: AppModel
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    var body: some View {
        GeometryReader { geometry in
            VStack(spacing: 8) {
                header
                if dynamicTypeSize.isAccessibilitySize || geometry.size.height < 570 {
                    ScrollView {
                        content(lensHeight: 140)
                    }
                } else {
                    content(lensHeight: nil)
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 8)
            .padding(.bottom, 14)
        }
    }

    private func content(lensHeight: CGFloat?) -> some View {
        VStack(spacing: 12) {
            DirectionStatusView(model: model)
            AuditoryLens(
                guidance: displayGuidance,
                reduceMotion: reduceMotion || displayGuidance == nil
            )
            .frame(height: lensHeight)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .accessibilityHidden(true)

            if model.directionReadiness.canUseDirection { status }

            VStack(spacing: 7) {
                Label(
                    LocalizedStringKey(feedbackLabelKey),
                    systemImage: model.directionReadiness.canUseDirection ? "waveform" : "pause.circle"
                )
                .font(.subheadline.weight(.medium))
                .foregroundStyle(model.directionReadiness.canUseDirection ? Color.hsDiscovery : Color.hsSecondary)
                Text("finder.safetyShort")
                    .font(.caption)
                    .foregroundStyle(Color.hsSecondary)
                    .multilineTextAlignment(.center)
            }
            .accessibilityElement(children: .combine)
        }
    }

    private var header: some View {
        HStack {
            Button(action: model.returnToPicker) {
                Label("common.backToStars", systemImage: "chevron.left")
                    .font(.subheadline)
                    .frame(minHeight: 44)
            }

            Spacer()
            Text(LocalizedStringKey(model.selectedStar.nameKey))
                .font(.headline)
        }
    }

    @ViewBuilder
    private var status: some View {
        VStack(spacing: 5) {
            Text(statusTitle)
                .font(.headline)
                .multilineTextAlignment(.center)
            if displayGuidance != nil {
                Text(LocalizedStringKey(model.directionReadiness == .approximate ? "finder.approximateFollowPulse" : "finder.followPulse"))
                    .font(.caption)
                    .foregroundStyle(Color.hsSecondary)
                    .multilineTextAlignment(.center)
            }
        }
        .padding(.horizontal, 14)
        .frame(maxWidth: .infinity, minHeight: 64)
        .accessibilityElement(children: .combine)
    }

    private var statusTitle: String {
        if model.sensors.isUnsafeMotion {
            return L10n.string("finder.pausedMoving")
        }

        if !model.isPractice && !model.hasUsableLiveLocation {
            let authorization = model.sensors.authorizationStatus
            if authorization == .denied || authorization == .restricted {
                return L10n.string("finder.locationDeniedSimple")
            }
            return L10n.string("finder.waitingLocation")
        }

        if !model.isPractice,
           let observation = model.selectedObservation,
           observation.altitudeDegrees < 2 {
            return L10n.string("finder.belowHorizonSimple")
        }

        if !model.isUsingSimulatedAim && !model.sensors.motionIsFresh {
            return L10n.string("finder.waitingSensors")
        }

        if !model.isUsingSimulatedAim {
            let accuracy = model.sensors.effectiveHeadingAccuracyDegrees
            if GuidanceMapper.headingQuality(accuracy) == .unavailable {
                return L10n.string("finder.calibrateSimple")
            }
        }

        guard let guidance = model.guidance else {
            return L10n.string("finder.waitingSensors")
        }
        if guidance.headingQuality == .unavailable {
            return L10n.string("finder.calibrateSimple")
        }
        return L10n.string("direction.\(guidance.direction.rawValue)")
    }

    private var feedbackLabelKey: String {
        if model.directionReadiness == .approximate { return "finder.approximateSoundHapticGuide" }
        return model.directionReadiness.canUseDirection ? "finder.soundHapticGuide" : "finder.guidePaused"
    }

    private var statusDetail: String {
        guard let guidance = displayGuidance else { return "" }
        return L10n.format(
            "finder.errorDetail",
            abs(guidance.azimuthErrorDegrees),
            abs(guidance.altitudeErrorDegrees),
            guidance.angularSeparationDegrees
        )
    }

    private var displayGuidance: GuidanceState? {
        guard model.directionReadiness.canUseDirection else { return nil }
        guard let guidance = model.guidance, guidance.canGuide else { return nil }
        guard !model.sensors.isUnsafeMotion else { return nil }
        guard model.isUsingSimulatedAim || (
            model.sensors.motionIsFresh
                && GuidanceMapper.headingQuality(
                    model.sensors.effectiveHeadingAccuracyDegrees
                ) != .unavailable
        ) else { return nil }
        if !model.isPractice {
            guard model.hasUsableLiveLocation,
                  let observation = model.selectedObservation,
                  observation.altitudeDegrees >= 2 else { return nil }
        }
        return guidance
    }

    private var shouldOfferPracticeFallback: Bool {
        guard !model.isPractice,
              !model.sensors.isUnsafeMotion else { return false }
        return !model.hasUsableLiveLocation
            || model.sensors.movementSafetyStatus != .ready
            || !model.sensors.motionIsFresh
            || GuidanceMapper.headingQuality(
                model.sensors.effectiveHeadingAccuracyDegrees
            ) == .unavailable
    }

    private var movementSafetyTitle: String? {
        switch model.sensors.movementSafetyStatus {
        case .ready:
            return nil
        case .unavailable:
            return L10n.string("finder.activityUnavailable")
        case .awaitingAuthorization:
            return L10n.string("finder.waitingActivityAuthorization")
        case .awaitingStationaryConfirmation:
            return L10n.string("finder.waitingStationaryConfirmation")
        case .denied:
            return L10n.string("finder.activityDenied")
        }
    }

    private var showsLowHorizonWarning: Bool {
        guard !model.isPractice,
              let altitude = model.selectedObservation?.altitudeDegrees else { return false }
        return altitude >= 0 && altitude < 5
    }

    private var practiceFallbackButton: some View {
        Button(action: model.usePracticeFallback) {
            Label("finder.usePracticeFallback", systemImage: "hand.tap")
                .font(.subheadline.weight(.medium))
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity, minHeight: 44)
        }
        .buttonStyle(.plain)
        .foregroundStyle(Color.hsDiscovery)
        .padding(.horizontal, 10)
        .nightPanel()
        .accessibilityHint(Text("finder.usePracticeFallbackHint"))
    }

    @ViewBuilder
    private func practiceControls(compact: Bool) -> some View {
        if model.simulatorEnabled {
            HStack(spacing: compact ? 6 : 10) {
                PracticeNudgeButton(systemName: "arrow.left", labelKey: "direction.left") {
                    model.nudgeSimulatedAim(azimuth: -5, altitude: 0)
                }
                PracticeNudgeButton(systemName: "arrow.down", labelKey: "direction.down") {
                    model.nudgeSimulatedAim(azimuth: 0, altitude: -5)
                }
                Button {
                    model.setSimulatorEnabled(false)
                } label: {
                    Text("practice.useDevice")
                        .font(.caption.weight(.medium))
                        .frame(maxWidth: .infinity, minHeight: 44)
                }
                .buttonStyle(.plain)
                .foregroundStyle(Color.hsDiscovery)
                PracticeNudgeButton(systemName: "arrow.up", labelKey: "direction.up") {
                    model.nudgeSimulatedAim(azimuth: 0, altitude: 5)
                }
                PracticeNudgeButton(systemName: "arrow.right", labelKey: "direction.right") {
                    model.nudgeSimulatedAim(azimuth: 5, altitude: 0)
                }
            }
            .padding(5)
            .nightPanel()
        } else {
            Button {
                model.setSimulatorEnabled(true)
            } label: {
                Label("practice.useSimulator", systemImage: "slider.horizontal.3")
                    .font(.caption.weight(.medium))
                    .frame(maxWidth: .infinity, minHeight: 44)
            }
            .buttonStyle(.plain)
            .foregroundStyle(Color.hsSecondary)
            .nightPanel()
        }
    }
}

private struct PracticeNudgeButton: View {
    let systemName: String
    let labelKey: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: systemName)
                .frame(width: 44, height: 44)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .foregroundStyle(Color.hsSecondary)
        .accessibilityLabel(Text(LocalizedStringKey(labelKey)))
    }
}

private struct AuditoryLens: View {
    let guidance: GuidanceState?
    let reduceMotion: Bool

    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 24.0, paused: reduceMotion)) { timeline in
            Canvas { context, size in
                let center = CGPoint(x: size.width / 2, y: size.height / 2)
                let maxRadius = min(size.width, size.height) * 0.43
                let clarity = guidance?.clarity ?? 0
                let interval = guidance?.pulseIntervalSeconds ?? 1.5
                let phase = reduceMotion
                    ? 0.35
                    : timeline.date.timeIntervalSinceReferenceDate
                        .truncatingRemainder(dividingBy: max(interval, 0.12))
                        / max(interval, 0.12)

                drawTrails(context: &context, size: size, center: center)
                drawRings(
                    context: &context,
                    center: center,
                    radius: maxRadius,
                    clarity: clarity,
                    phase: phase
                )
                drawDirectionArc(
                    context: &context,
                    center: center,
                    radius: maxRadius,
                    azimuthError: guidance?.azimuthErrorDegrees
                )
                drawAltitudeMark(
                    context: &context,
                    center: center,
                    radius: maxRadius,
                    altitudeError: guidance?.altitudeErrorDegrees
                )
                drawCenter(context: &context, center: center, clarity: clarity)
            }
        }
    }

    private func drawTrails(context: inout GraphicsContext, size: CGSize, center: CGPoint) {
        var path = Path()
        path.move(to: CGPoint(x: 8, y: center.y * 0.62))
        path.addCurve(
            to: CGPoint(x: size.width - 8, y: center.y * 0.42),
            control1: CGPoint(x: size.width * 0.32, y: center.y * 0.18),
            control2: CGPoint(x: size.width * 0.66, y: center.y * 0.88)
        )
        context.stroke(path, with: .color(.hsSecondary.opacity(0.09)), lineWidth: 0.55)
    }

    private func drawRings(
        context: inout GraphicsContext,
        center: CGPoint,
        radius: CGFloat,
        clarity: Double,
        phase: Double
    ) {
        for index in 1...3 {
            let base = radius * CGFloat(index) / 3.0
            let drift = reduceMotion ? 0 : CGFloat(phase) * radius / 3.0
            let ringRadius = (base + drift).truncatingRemainder(dividingBy: radius)
            let rect = CGRect(
                x: center.x - ringRadius,
                y: center.y - ringRadius,
                width: ringRadius * 2,
                height: ringRadius * 2
            )
            let opacity = 0.07 + clarity * 0.18 + Double(index == 1 ? 0.08 : 0)
            context.stroke(
                Path(ellipseIn: rect),
                with: .color(Color.hsDiscovery.opacity(opacity)),
                lineWidth: clarity > 0.78 ? 1.05 : 0.65
            )
        }
    }

    private func drawDirectionArc(
        context: inout GraphicsContext,
        center: CGPoint,
        radius: CGFloat,
        azimuthError: Double?
    ) {
        guard let azimuthError else { return }
        let clamped = AngleMath.clamp(azimuthError, min: -150, max: 150)
        let middle = -90.0 + clamped * 0.72
        let halfWidth = abs(azimuthError) > 135 ? 54.0 : 22.0
        var arc = Path()
        arc.addArc(
            center: center,
            radius: radius,
            startAngle: .degrees(middle - halfWidth),
            endAngle: .degrees(middle + halfWidth),
            clockwise: false
        )
        context.stroke(arc, with: .color(.hsGuide.opacity(0.9)), style: .init(lineWidth: 1.2, lineCap: .round))
    }

    private func drawAltitudeMark(
        context: inout GraphicsContext,
        center: CGPoint,
        radius: CGFloat,
        altitudeError: Double?
    ) {
        guard let altitudeError else { return }
        let normalized = AngleMath.clamp(altitudeError / 45.0, min: -1, max: 1)
        let y = center.y - CGFloat(normalized) * radius * 0.7
        var line = Path()
        line.move(to: CGPoint(x: center.x - 12, y: y))
        line.addLine(to: CGPoint(x: center.x + 12, y: y))
        context.stroke(line, with: .color(.hsSecondary.opacity(0.55)), lineWidth: 0.8)
    }

    private func drawCenter(context: inout GraphicsContext, center: CGPoint, clarity: Double) {
        let radius = CGFloat(9.0 + clarity * 7.0)
        let rect = CGRect(x: center.x - radius, y: center.y - radius, width: radius * 2, height: radius * 2)
        context.stroke(Path(ellipseIn: rect), with: .color(.hsDiscovery.opacity(0.55 + clarity * 0.4)), lineWidth: 1.0)

        var cross = Path()
        cross.move(to: CGPoint(x: center.x - 4, y: center.y))
        cross.addLine(to: CGPoint(x: center.x + 4, y: center.y))
        cross.move(to: CGPoint(x: center.x, y: center.y - 4))
        cross.addLine(to: CGPoint(x: center.x, y: center.y + 4))
        context.stroke(cross, with: .color(.hsText.opacity(0.72)), lineWidth: 0.7)
    }
}
