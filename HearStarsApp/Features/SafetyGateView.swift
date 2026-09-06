import SwiftUI

struct SafetyGateView: View {
    @ObservedObject var model: AppModel
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    var body: some View {
        GeometryReader { geometry in
            ViewThatFits {
                if !dynamicTypeSize.isAccessibilitySize && geometry.size.height >= 620 {
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
        VStack(spacing: 0) {
            header

            Spacer()

            standingSymbol

            VStack(spacing: 12) {
                Text("safety.title")
                    .font(.title2.weight(.medium))
                    .multilineTextAlignment(.center)
                Text("safety.body")
                    .font(.body)
                    .foregroundStyle(Color.hsSecondary)
                    .multilineTextAlignment(.center)
            }
            .padding(.top, 28)
            .accessibilityElement(children: .combine)

            Spacer()

            notNavigationText(key: "safety.notNavigation")
                .font(.caption)
                .padding(.bottom, 14)

            confirmButton
        }
    }

    private var compactContent: some View {
        VStack(spacing: 8) {
            header

            Spacer(minLength: 0)

            Image(systemName: "figure.stand")
                .font(.system(size: 24, weight: .ultraLight))
                .foregroundStyle(Color.hsDiscovery)
                .accessibilityHidden(true)

            Text("safety.title")
                .font(.headline)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)

            Text("safety.compactBody")
                .font(.caption)
                .foregroundStyle(Color.hsSecondary)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)

            Spacer(minLength: 0)

            notNavigationText(key: "safety.compactNotNavigation")
                .font(.caption2)

            confirmButton
        }
    }

    private var minimumContent: some View {
        VStack(spacing: 8) {
            header

            Spacer(minLength: 0)

            Text("safety.minimumBody")
                .font(.caption)
                .foregroundStyle(Color.hsSecondary)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)

            Spacer(minLength: 0)

            confirmButton
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
        }
    }

    private var standingSymbol: some View {
        ZStack {
            Circle()
                .stroke(Color.hsSecondary.opacity(0.25), lineWidth: 0.75)
                .frame(width: 150, height: 150)
            Image(systemName: "figure.stand")
                .font(.system(size: 50, weight: .ultraLight))
                .foregroundStyle(Color.hsDiscovery)
        }
        .accessibilityHidden(true)
    }

    private func notNavigationText(key: LocalizedStringKey) -> some View {
        Text(key)
            .foregroundStyle(Color.hsSecondary)
            .multilineTextAlignment(.center)
            .fixedSize(horizontal: false, vertical: true)
    }

    private var confirmButton: some View {
        Button(action: model.confirmStoppedAndSafe) {
            Text("safety.confirm")
                .font(.headline)
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity, minHeight: 54)
                .background(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .fill(Color.hsDiscovery.opacity(0.92))
                )
                .foregroundStyle(Color.hsNight)
        }
        .buttonStyle(.plain)
    }
}
