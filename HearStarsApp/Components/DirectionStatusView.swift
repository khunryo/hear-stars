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
                DirectionStatusCopy(state: state)
            }
            .accessibilityElement(children: .combine)

            if state == .locationDenied || state == .locationServicesOff {
                Button("readiness.openSettings", action: model.openAppSettings)
                    .frame(minHeight: 44)
            } else if state == .locationDelayed || state == .directionDelayed || state == .calibrating {
                Button("readiness.retry", action: model.retryDirectionSetup)
                    .frame(minHeight: 44)
            }
            if state == .calibrating || state == .directionDelayed || state == .checkingDirection {
                DirectionDiagnosticsView(sensors: model.sensors)
            }
        }
        .buttonStyle(.plain)
        .tint(Color.hsDiscovery)
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .nightPanel()
    }
}

/// On-device only; no logging, persistence, or export of location/sensor data.
private struct DirectionDiagnosticsView: View {
    @ObservedObject var sensors: SensorService

    var body: some View {
        DisclosureGroup("diagnostics.title") {
            Text(verbatim: sensors.headingDiagnosticSummary)
                .font(.caption)
                .foregroundStyle(Color.hsSecondary)
                .frame(maxWidth: .infinity, alignment: .leading)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.top, 4)
        }
        .font(.caption)
    }
}
