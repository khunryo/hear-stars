import SwiftUI

/// The same snapshot used for the guidance decision, not live mutable readings.
struct DirectionDiagnosticDetails: View {
    let current: DirectionDiagnosticSnapshot
    let lastStop: DirectionDiagnosticSnapshot?
    let build: String
    var bundle: Bundle = .main

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(verbatim: "Build " + build)
            Text(verbatim: current.summary(bundle: bundle))
            if let lastStop {
                Divider()
                Text(verbatim: L10n.string("diagnostics.lastStop", bundle: bundle))
                    .fontWeight(.semibold)
                Text(verbatim: lastStop.summary(bundle: bundle))
            }
            Text(verbatim: L10n.string("diagnostics.snapshotNote", bundle: bundle))
        }
        .font(.caption)
        .foregroundStyle(Color.hsSecondary)
        .fixedSize(horizontal: false, vertical: true)
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
