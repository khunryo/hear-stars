import CoreLocation
import HearStarsCore
import SwiftUI

struct ConstellationView: View {
    @ObservedObject var model: AppModel
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        VStack(spacing: 14) {
            HStack {
                Button(action: model.returnToDiscovery) {
                    Image(systemName: "xmark")
                        .frame(width: 44, height: 44)
                }
                .accessibilityLabel(Text("common.close"))

                Spacer()
                Text("constellation.title")
                    .font(.headline)
                Spacer()
                Color.clear.frame(width: 44, height: 44)
            }

            Text("constellation.badge")
                .font(.caption.weight(.semibold))
                .padding(.horizontal, 11)
                .padding(.vertical, 7)
                .overlay(Capsule().stroke(Color.hsSecondary.opacity(0.5), lineWidth: 0.8))
                .accessibilityHidden(true)

            GeometryReader { geometry in
                ConstellationField(
                    guide: .forStar(model.selectedStar.id),
                    offset: pointingOffset(in: geometry.size),
                    reduceMotion: reduceMotion
                )
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .nightPanel()
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(Text(accessibilityDescription))

            VStack(spacing: 5) {
                Text(LocalizedStringKey(model.selectedStar.nameKey))
                    .font(.title3.weight(.medium))
                Text(LocalizedStringKey(ConstellationGuide.forStar(model.selectedStar.id).constellationKey))
                    .font(.subheadline)
                    .foregroundStyle(Color.hsSecondary)
                Text(LocalizedStringKey(statusKey))
                    .font(.caption)
                    .foregroundStyle(Color.hsSecondary)
                    .multilineTextAlignment(.center)
            }
            .accessibilityElement(children: .combine)

            Button(action: model.findAnotherStar) {
                Text("discovery.next")
                    .font(.headline)
                    .frame(maxWidth: .infinity, minHeight: 52)
                    .background(
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .fill(Color.hsDiscovery.opacity(0.92))
                    )
                    .foregroundStyle(Color.hsNight)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 16)
        .padding(.top, 8)
        .padding(.bottom, 14)
    }

    private var statusKey: String {
        if model.sensors.isUnsafeMotion { return "constellation.stopped" }
        if model.sensors.aim == nil { return "constellation.waiting" }
        return "constellation.move"
    }

    private var accessibilityDescription: String {
        L10n.format(
            "constellation.accessibility",
            L10n.string(model.selectedStar.nameKey),
            L10n.string(ConstellationGuide.forStar(model.selectedStar.id).constellationKey)
        )
    }

    private func pointingOffset(in size: CGSize) -> CGSize {
        guard let target = model.selectedObservation,
              let aim = model.sensors.aim else { return .zero }
        let azimuthError = signedDegrees(target.azimuthDegrees - aim.azimuthDegrees)
        let altitudeError = target.altitudeDegrees - aim.altitudeDegrees
        let x = max(-1.0, min(1.0, azimuthError / 42.0))
        let y = max(-1.0, min(1.0, altitudeError / 30.0))
        return CGSize(width: size.width * CGFloat(x) * 0.24, height: -size.height * CGFloat(y) * 0.22)
    }

    private func signedDegrees(_ degrees: Double) -> Double {
        var value = degrees.truncatingRemainder(dividingBy: 360)
        if value > 180 { value -= 360 }
        if value <= -180 { value += 360 }
        return value
    }
}

private struct ConstellationField: View {
    let guide: ConstellationGuide
    let offset: CGSize
    let reduceMotion: Bool

    var body: some View {
        Canvas { context, size in
            let center = CGPoint(x: size.width / 2, y: size.height / 2)
            let scale = min(size.width, size.height) * 0.74

            for row in 1...7 {
                for column in 1...5 {
                    let point = CGPoint(
                        x: size.width * CGFloat(column) / 6,
                        y: size.height * CGFloat(row) / 8
                    )
                    context.fill(
                        Path(ellipseIn: CGRect(x: point.x - 0.7, y: point.y - 0.7, width: 1.4, height: 1.4)),
                        with: .color(Color.hsSecondary.opacity(0.35))
                    )
                }
            }

            context.translateBy(x: offset.width, y: offset.height)
            let points = guide.points.map {
                CGPoint(x: center.x + $0.x * scale, y: center.y + $0.y * scale)
            }
            for link in guide.links {
                var line = Path()
                line.move(to: points[link.0])
                line.addLine(to: points[link.1])
                context.stroke(line, with: .color(.hsDiscovery.opacity(0.8)), lineWidth: 1.05)
            }
            for (index, point) in points.enumerated() {
                let radius: CGFloat = index == guide.targetIndex ? 5.4 : 3.0
                context.fill(
                    Path(ellipseIn: CGRect(x: point.x - radius, y: point.y - radius, width: radius * 2, height: radius * 2)),
                    with: .color(index == guide.targetIndex ? .hsDiscovery : .hsText)
                )
                if index == guide.targetIndex {
                    context.stroke(
                        Path(ellipseIn: CGRect(x: point.x - 10, y: point.y - 10, width: 20, height: 20)),
                        with: .color(.hsDiscovery.opacity(0.7)),
                        lineWidth: 0.9
                    )
                }
            }
        }
        .animation(reduceMotion ? nil : .easeOut(duration: 0.2), value: offset)
    }
}

private struct ConstellationGuide {
    let constellationKey: String
    let points: [CGPoint]
    let links: [(Int, Int)]
    let targetIndex: Int

    static func forStar(_ id: String) -> ConstellationGuide {
        switch id {
        case "polaris":
            return .init(
                constellationKey: "constellation.umi",
                points: [CGPoint(x: -0.42, y: 0.20), CGPoint(x: -0.20, y: 0.02), CGPoint(x: 0.02, y: 0.13), CGPoint(x: 0.25, y: -0.04), CGPoint(x: 0.40, y: -0.25), CGPoint(x: 0.18, y: -0.32)],
                links: [(0, 1), (1, 2), (2, 3), (3, 4), (3, 5)],
                targetIndex: 4
            )
        case "sirius":
            return .init(
                constellationKey: "constellation.cma",
                points: [CGPoint(x: -0.42, y: -0.20), CGPoint(x: -0.18, y: -0.02), CGPoint(x: 0.08, y: 0.16), CGPoint(x: 0.38, y: 0.24), CGPoint(x: 0.12, y: -0.28)],
                links: [(0, 1), (1, 2), (2, 3), (1, 4)],
                targetIndex: 3
            )
        case "vega":
            return .init(
                constellationKey: "constellation.lyr",
                points: [CGPoint(x: -0.32, y: -0.18), CGPoint(x: -0.05, y: -0.34), CGPoint(x: 0.26, y: -0.12), CGPoint(x: 0.18, y: 0.22), CGPoint(x: -0.18, y: 0.24)],
                links: [(0, 1), (1, 2), (2, 3), (3, 4), (4, 0)],
                targetIndex: 1
            )
        default:
            return .init(
                constellationKey: "constellation.ori",
                points: [CGPoint(x: -0.40, y: -0.25), CGPoint(x: -0.12, y: -0.04), CGPoint(x: 0.14, y: 0.10), CGPoint(x: 0.40, y: 0.28), CGPoint(x: 0.10, y: -0.26), CGPoint(x: -0.18, y: 0.27)],
                links: [(0, 1), (1, 2), (2, 3), (1, 4), (2, 5)],
                targetIndex: id == "rigel" ? 3 : 1
            )
        }
    }
}
