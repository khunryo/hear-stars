import SwiftUI

struct DiscoveryView: View {
    @ObservedObject var model: AppModel
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @State private var revealed = false

    var body: some View {
        VStack(spacing: 0) {
            Button(action: model.returnToPicker) {
                Label("common.backToStars", systemImage: "chevron.left")
                    .font(.body.weight(.medium))
                    .multilineTextAlignment(.leading)
                    .fixedSize(horizontal: false, vertical: true)
                    .frame(minHeight: 44)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .foregroundStyle(Color.hsText)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 16)
            .padding(.top, 4)

            GeometryReader { geometry in
                ViewThatFits(in: .vertical) {
                    if !dynamicTypeSize.isAccessibilitySize && geometry.size.height >= 700 {
                        regularContent
                            .padding(24)
                    } else {
                        compactContent
                            .padding(16)
                    }

                    compactContent
                        .padding(16)

                    minimumContent
                        .padding(12)

                    ScrollView {
                        minimumContent
                            .padding(12)
                            .frame(maxWidth: .infinity)
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .onAppear {
            if reduceMotion {
                revealed = true
            } else {
                withAnimation(.easeOut(duration: 0.45)) { revealed = true }
            }
        }
    }

    private var regularContent: some View {
        VStack(spacing: 20) {
            Spacer()

            discoveryMark(compact: false)

            discoveryCopy(compact: false)

            Spacer()

            actions(compact: false)
        }
    }

    private var compactContent: some View {
        VStack(spacing: 9) {
            Spacer(minLength: 0)

            discoveryMark(compact: true)
            discoveryCopy(compact: true)

            Spacer(minLength: 0)

            actions(compact: true)
        }
    }

    private var minimumContent: some View {
        VStack(spacing: 7) {
            Spacer(minLength: 0)

            discoveryMark(compact: true, minimum: true)
            discoveryCopy(compact: true, minimum: true)

            Spacer(minLength: 0)

            actions(compact: true)
        }
    }

    private func discoveryMark(compact: Bool, minimum: Bool = false) -> some View {
        let baseDiameter: CGFloat = minimum ? 44 : (compact ? 60 : 96)
        let revealedDiameter: CGFloat = minimum ? 56 : (compact ? 80 : 184)
        let glyphDiameter: CGFloat = minimum ? 28 : (compact ? 34 : 52)

        return ZStack {
            Circle()
                .stroke(Color.hsDiscovery.opacity(0.28), lineWidth: 0.8)
                .frame(
                    width: revealed && !reduceMotion ? revealedDiameter : baseDiameter,
                    height: revealed && !reduceMotion ? revealedDiameter : baseDiameter
                )
            Circle()
                .stroke(Color.hsDiscovery.opacity(0.72), lineWidth: 1.1)
                .frame(width: baseDiameter, height: baseDiameter)
            DiscoveryGlyph(seed: model.selectedStar.id)
                .frame(width: glyphDiameter, height: glyphDiameter)
        }
        .frame(width: revealedDiameter, height: revealedDiameter)
        .animation(reduceMotion ? nil : .easeOut(duration: 0.45), value: revealed)
        .accessibilityHidden(true)
    }

    private func discoveryCopy(compact: Bool, minimum: Bool = false) -> some View {
        VStack(spacing: minimum ? 3 : (compact ? 5 : 8)) {
            Text("discovery.title")
                .font(minimum ? .caption.weight(.semibold) : (compact ? .headline : .title2.weight(.medium)))
            Text(LocalizedStringKey(model.selectedStar.nameKey))
                .font(minimum ? .headline.weight(.light) : (compact ? .title2.weight(.light) : .title.weight(.light)))
                .tracking(minimum ? 0.4 : (compact ? 1.0 : 1.8))
            Text("discovery.body")
                .font(minimum ? .caption2 : (compact ? .caption : .body))
                .foregroundStyle(Color.hsSecondary)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
        }
        .multilineTextAlignment(.center)
        .accessibilityElement(children: .combine)
    }

    private func actions(compact: Bool) -> some View {
        VStack(spacing: 10) {
            Button(action: model.showConstellation) {
                Text("discovery.constellation")
                    .font(compact ? .subheadline.weight(.semibold) : .headline)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .frame(maxWidth: .infinity, minHeight: 52)
                    .background(
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .fill(Color.hsDiscovery.opacity(0.92))
                    )
                    .foregroundStyle(Color.hsNight)
            }
            .buttonStyle(.plain)

            Button(action: model.restartFinding) {
                Text("discovery.retry")
                    .font(compact ? .subheadline.weight(.semibold) : .headline)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .frame(maxWidth: .infinity, minHeight: 48)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .stroke(Color.hsSecondary.opacity(0.55), lineWidth: 0.8)
                    )
                    .foregroundStyle(Color.hsText)
            }
            .buttonStyle(.plain)
        }
    }

}

private struct DiscoveryGlyph: View {
    let seed: String

    var body: some View {
        Canvas { context, size in
            let center = CGPoint(x: size.width / 2, y: size.height / 2)
            let signature = stableSignature
            let count = 7 + Int(signature % 5)
            let phase = Double((signature >> 8) & 0xFFFF) / Double(UInt16.max) * Double.pi * 2
            let scale = min(size.width, size.height)

            for index in 0..<count {
                let angle = phase + Double(index) / Double(count) * Double.pi * 2
                let shift = UInt64((index * 5) % 56)
                let sample = (signature >> shift) & 0x1F
                let radiusRatio = 0.28 + Double(sample) / 31.0 * 0.19
                let radius = scale * CGFloat(radiusRatio)
                let lineWidth = 0.55 + CGFloat((sample >> 3) & 0x03) * 0.18
                var path = Path()
                path.move(to: center)
                path.addLine(to: CGPoint(
                    x: center.x + CGFloat(cos(angle)) * radius,
                    y: center.y + CGFloat(sin(angle)) * radius
                ))
                context.stroke(path, with: .color(.hsDiscovery), lineWidth: lineWidth)
            }

            let innerRatio = 0.09 + Double((signature >> 48) & 0x07) / 100.0
            let innerRadius = scale * CGFloat(innerRatio)
            context.stroke(
                Path(ellipseIn: CGRect(
                    x: center.x - innerRadius,
                    y: center.y - innerRadius,
                    width: innerRadius * 2,
                    height: innerRadius * 2
                )),
                with: .color(.hsDiscovery.opacity(0.72)),
                lineWidth: 0.65
            )
        }
    }

    private var stableSignature: UInt64 {
        var value: UInt64 = 14_695_981_039_346_656_037
        for byte in seed.utf8 {
            value ^= UInt64(byte)
            value &*= 1_099_511_628_211
        }
        return value
    }
}
