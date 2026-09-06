import HearStarsCore
import SwiftUI

struct TargetPickerView: View {
    @ObservedObject var model: AppModel
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    var body: some View {
        GeometryReader { geometry in
            let compact = geometry.size.height < 700 || dynamicTypeSize.isAccessibilitySize

            VStack(alignment: .leading, spacing: compact ? 9 : 14) {
                Text("app.title")
                    .font(.caption.weight(.semibold))
                    .tracking(1.6)
                    .foregroundStyle(Color.hsSecondary)

                Spacer(minLength: compact ? 2 : 12)

                VStack(alignment: .leading, spacing: 7) {
                    Text("picker.simpleTitle")
                        .font(compact ? .title2.weight(.medium) : .largeTitle.weight(.light))
                    Text("picker.simpleBody")
                        .font(compact ? .caption : .body)
                        .foregroundStyle(Color.hsSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer(minLength: compact ? 2 : 8)

                VStack(spacing: compact ? 7 : 10) {
                    ForEach(model.stars) { star in
                        StarChoiceRow(
                            star: star,
                            observation: model.observations[star.id],
                            compact: compact,
                            action: { model.startFinding(star) }
                        )
                    }
                }

                Spacer(minLength: compact ? 2 : 10)

                Label("picker.outputHint", systemImage: "waveform")
                    .font(.caption)
                    .foregroundStyle(Color.hsSecondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .accessibilityElement(children: .combine)
            }
            .padding(.horizontal, 20)
            .padding(.top, 14)
            .padding(.bottom, 12)
        }
    }
}

private struct StarChoiceRow: View {
    let star: Star
    let observation: HorizontalCoordinate?
    let compact: Bool
    let action: () -> Void

    private var isAvailable: Bool {
        guard let observation else { return true }
        return observation.altitudeDegrees >= 2
    }

    var body: some View {
        Button(action: action) {
            HStack(spacing: 13) {
                StarGlyph(seed: star.id)

                Text(LocalizedStringKey(star.nameKey))
                    .font(compact ? .body.weight(.medium) : .title3.weight(.medium))
                    .foregroundStyle(Color.hsText)

                Spacer()

                if observation != nil {
                    Text(LocalizedStringKey(
                        isAvailable ? "picker.availableNow" : "picker.belowNow"
                    ))
                        .font(.caption2)
                        .foregroundStyle(isAvailable ? Color.hsSecondary : Color.hsGuide)
                }

                Image(systemName: "chevron.right")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Color.hsSecondary)
                    .accessibilityHidden(true)
            }
            .padding(.horizontal, 15)
            .frame(maxWidth: .infinity, minHeight: compact ? 46 : 56)
            .background(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(Color.hsPanel)
                    .overlay(
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .stroke(Color.hsSecondary.opacity(0.18), lineWidth: 0.7)
                    )
            )
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .disabled(!isAvailable)
        .opacity(isAvailable ? 1 : 0.55)
        .accessibilityLabel(accessibilityLabel)
        .accessibilityHint(Text(LocalizedStringKey(
            isAvailable ? "picker.starHint" : "picker.belowHint"
        )))
    }

    private var accessibilityLabel: String {
        let name = L10n.string(star.nameKey)
        guard observation != nil else { return name }
        return L10n.format(
            isAvailable ? "picker.voiceAvailableNow" : "picker.voiceBelow",
            name
        )
    }
}

private struct StarCard: View {
    let star: Star
    let observation: HorizontalCoordinate?
    let isSelected: Bool
    let isPractice: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 9) {
                HStack {
                    StarGlyph(seed: star.id)
                    Spacer()
                    if isSelected {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(Color.hsDiscovery)
                    }
                }
                Spacer(minLength: 2)
                Text(LocalizedStringKey(star.nameKey))
                    .font(.headline)
                    .foregroundStyle(Color.hsText)
                    .lineLimit(1)
                    .minimumScaleFactor(0.72)
                Text(star.designation)
                    .font(.caption.monospaced())
                    .foregroundStyle(Color.hsSecondary)
                observationLine
                    .font(.caption2.monospacedDigit())
                    .foregroundStyle(Color.hsSecondary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.72)
            }
            .padding(15)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .fill(Color.hsPanel)
                    .overlay(
                        RoundedRectangle(cornerRadius: 24, style: .continuous)
                            .stroke(
                                isSelected ? Color.hsGuide.opacity(0.95) : Color.hsSecondary.opacity(0.2),
                                lineWidth: isSelected ? 1.1 : 0.7
                            )
                    )
            )
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(accessibilityLabel)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }

    @ViewBuilder
    private var observationLine: some View {
        if let observation {
            if observation.isAboveGeometricHorizon,
               !isPractice,
               observation.altitudeDegrees < 5 {
                Text(L10n.format(
                    "picker.lowHorizon",
                    compassName(observation.azimuthDegrees),
                    observation.altitudeDegrees
                ))
            } else if observation.isAboveGeometricHorizon || isPractice {
                Text(L10n.format(
                    "picker.coordinate",
                    compassName(observation.azimuthDegrees),
                    observation.altitudeDegrees
                ))
            } else {
                Text("picker.belowHorizon")
            }
        } else {
            Text("picker.needsLocation")
        }
    }

    private var accessibilityLabel: String {
        let name = L10n.string(star.nameKey)
        guard let observation else {
            return L10n.format("picker.voiceNeedsLocation", name)
        }
        if !observation.isAboveGeometricHorizon && !isPractice {
            return L10n.format("picker.voiceBelow", name)
        }
        if !isPractice && observation.altitudeDegrees < 5 {
            return L10n.format(
                "picker.voiceLowHorizon",
                name,
                compassName(observation.azimuthDegrees),
                observation.altitudeDegrees
            )
        }
        return L10n.format(
            "picker.voiceVisible",
            name,
            compassName(observation.azimuthDegrees),
            observation.altitudeDegrees
        )
    }

    private func compassName(_ azimuth: Double) -> String {
        let keys = ["north", "northeast", "east", "southeast", "south", "southwest", "west", "northwest"]
        let index = Int((AngleMath.normalizeDegrees(azimuth) + 22.5) / 45.0) % 8
        return L10n.string("compass.\(keys[index])")
    }
}

private struct StarGlyph: View {
    let seed: String

    var body: some View {
        Canvas { context, size in
            let center = CGPoint(x: size.width / 2, y: size.height / 2)
            let spokeCount = 4 + seed.unicodeScalars.reduce(0) { $0 + Int($1.value) } % 5
            let radius = min(size.width, size.height) * 0.4
            for index in 0..<spokeCount {
                let angle = Double(index) / Double(spokeCount) * Double.pi * 2
                var path = Path()
                path.move(to: center)
                path.addLine(to: CGPoint(
                    x: center.x + CGFloat(cos(angle)) * radius,
                    y: center.y + CGFloat(sin(angle)) * radius
                ))
                context.stroke(path, with: .color(.hsSecondary), lineWidth: index.isMultiple(of: 2) ? 1 : 0.6)
            }
            context.fill(Path(ellipseIn: CGRect(x: center.x - 2, y: center.y - 2, width: 4, height: 4)), with: .color(.hsDiscovery))
        }
        .frame(width: 34, height: 34)
        .accessibilityHidden(true)
    }
}

private extension Array {
    func chunked(into size: Int) -> [[Element]] {
        stride(from: 0, to: count, by: size).map { start in
            Array(self[start..<Swift.min(start + size, count)])
        }
    }
}
