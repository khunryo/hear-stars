import HearStarsCore
import SwiftUI

/// Resolve the complete key first; interpolated LocalizedStringKey literals
/// otherwise look up a format such as "readiness.%@.title".
struct DirectionStatusCopy: View {
    let state: DirectionReadiness
    var bundle: Bundle = .main
    var overridePrefix: String? = nil

    var title: String { L10n.string(overridePrefix.map { $0 + ".title" } ?? state.titleLocalizationKey, bundle: bundle) }
    var detail: String { L10n.string(overridePrefix.map { $0 + ".body" } ?? state.bodyLocalizationKey, bundle: bundle) }

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(verbatim: title)
                .font(.subheadline.weight(.semibold))
            Text(verbatim: detail)
                .font(.caption)
                .foregroundStyle(Color.hsSecondary)
        }
        .fixedSize(horizontal: false, vertical: true)
    }
}
