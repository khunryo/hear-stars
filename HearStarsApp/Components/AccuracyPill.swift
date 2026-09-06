import HearStarsCore
import SwiftUI

struct AccuracyPill: View {
    let accuracy: Double?

    private var quality: HeadingQuality {
        GuidanceMapper.headingQuality(accuracy)
    }

    private var titleKey: String {
        "accuracy.\(quality.rawValue)"
    }

    var body: some View {
        HStack(spacing: 6) {
            Circle()
                .fill(quality == .good ? Color.hsDiscovery : Color.hsGuide)
                .frame(width: 6, height: 6)
            if let accuracy, accuracy >= 0 {
                Text(L10n.format("accuracy.value", L10n.string(titleKey), accuracy))
            } else {
                Text(LocalizedStringKey(titleKey))
            }
        }
        .font(.caption.monospacedDigit())
        .foregroundStyle(Color.hsSecondary)
        .padding(.horizontal, 10)
        .frame(minHeight: 32)
        .background(Capsule().fill(Color.hsPanel))
        .accessibilityElement(children: .combine)
    }
}

