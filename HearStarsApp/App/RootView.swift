import SwiftUI

struct RootView: View {
    @ObservedObject var model: AppModel
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        ZStack {
            Color.hsNight.ignoresSafeArea()

            switch model.route {
            case .picker:
                TargetPickerView(model: model)
                    .transition(.opacity)
            case .safety:
                SafetyGateView(model: model)
                    .transition(.opacity)
            case .calibration:
                CalibrationView(model: model)
                    .transition(.opacity)
            case .finder:
                FinderView(model: model)
                    .transition(.opacity)
            case .discovery:
                DiscoveryView(model: model)
                    .transition(.opacity)
            case .constellation:
                ConstellationView(model: model)
                    .transition(.opacity)
            }
        }
        .foregroundStyle(Color.hsText)
        .animation(reduceMotion ? nil : .easeInOut(duration: 0.24), value: model.route)
    }
}
