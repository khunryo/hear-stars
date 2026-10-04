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
                    Image(systemName: state.canConfirmAlignment ? "checkmark.circle.fill" : "info.circle")
                        .foregroundStyle(state.canConfirmAlignment ? Color.hsDiscovery : Color.hsGuide)
                        .accessibilityHidden(true)
                }
                DirectionStatusCopy(state: state, overridePrefix: model.directionDiagnostics?.copyPrefix)
            }
            .accessibilityElement(children: .combine)

            if state == .locationDenied || state == .locationServicesOff {
                Button("readiness.openSettings", action: model.openAppSettings)
                    .frame(minHeight: 44)
            } else if state == .locationDelayed || state == .directionDelayed || state == .calibrating {
                Button("readiness.retry", action: model.retryDirectionSetup)
                    .frame(minHeight: 44)
            }
            if !model.isUsingSimulatedAim, let current = model.directionDiagnostics,
               state != .ready || model.lastStopDiagnostics != nil {
                DisclosureGroup("diagnostics.title", isExpanded: $model.diagnosticsExpanded) {
                    DirectionDiagnosticDetails(
                        current: current, lastStop: model.lastStopDiagnostics,
                        build: Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "—"
                    )
                    .padding(.top, 4)
                }
                .font(.caption)
            }
        }
        .buttonStyle(.plain)
        .tint(Color.hsDiscovery)
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .nightPanel()
    }
}
