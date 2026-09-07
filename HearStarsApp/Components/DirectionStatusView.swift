import HearStarsCore
import SwiftUI

struct DirectionStatusView: View {
    @ObservedObject var model: AppModel

    private var state: DirectionReadiness { model.directionReadiness }
    private var isWaiting: Bool {
        state == .locating || state == .checkingDirection || state == .locationPermission
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .top, spacing: 10) {
                if isWaiting {
                    ProgressView()
                        .tint(Color.hsSecondary)
                        .accessibilityHidden(true)
                } else {
                    Image(systemName: state.canUseDirection ? "checkmark.circle.fill" : "info.circle")
                        .foregroundStyle(state.canUseDirection ? Color.hsDiscovery : Color.hsGuide)
                        .accessibilityHidden(true)
                }
                VStack(alignment: .leading, spacing: 4) {
                    Text(LocalizedStringKey("readiness.\(state.rawValue).title"))
                        .font(.subheadline.weight(.semibold))
                    Text(LocalizedStringKey("readiness.\(state.rawValue).body"))
                        .font(.caption)
                        .foregroundStyle(Color.hsSecondary)
                }
                .fixedSize(horizontal: false, vertical: true)
            }
            .accessibilityElement(children: .combine)

            if state == .locationDenied || state == .locationServicesOff {
                Button("readiness.openSettings", action: model.openAppSettings)
                    .frame(minHeight: 44)
            } else if state == .locationDelayed || state == .directionDelayed || state == .calibrating {
                Button("readiness.retry", action: model.retryDirectionSetup)
                    .frame(minHeight: 44)
            }
        }
        .buttonStyle(.plain)
        .tint(Color.hsDiscovery)
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .nightPanel()
    }
}
