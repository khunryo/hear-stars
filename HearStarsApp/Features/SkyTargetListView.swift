import HearStarsCore
import SwiftUI

/// Accessible alternative to picking a small dot or a moving constellation label.
struct SkyTargetListView: View {
    @ObservedObject var model: AppModel
    @Environment(\.dismiss) private var dismiss
    private var groups: [SkyConstellation] {
        SkyCatalog.constellations.sorted {
            let leftVisible = SkyCatalog.anchor(for: $0.id, observations: model.observations) != nil
            let rightVisible = SkyCatalog.anchor(for: $1.id, observations: model.observations) != nil
            if leftVisible != rightVisible { return leftVisible }
            return L10n.string($0.nameKey).localizedStandardCompare(L10n.string($1.nameKey)) == .orderedAscending
        }
    }
    var body: some View {
        NavigationStack {
            List(groups) { group in
                let anchor = SkyCatalog.anchor(for: group.id, observations: model.observations)
                Button {
                    model.selectSkyTarget(.constellation(group.id)); dismiss()
                } label: {
                    VStack(alignment: .leading, spacing: 5) {
                        Text(LocalizedStringKey(group.nameKey)).font(.headline)
                        if let anchor {
                            Text(L10n.format("sky.anchor", L10n.string(anchor.nameKey)))
                                .font(.caption).foregroundStyle(Color.hsSecondary)
                        } else {
                            Text(LocalizedStringKey(model.observations.isEmpty ? "location.waiting" : "sky.notVisible"))
                                .font(.caption).foregroundStyle(Color.hsSecondary)
                        }
                    }.frame(minHeight: 44)
                }
                .buttonStyle(.plain).disabled(anchor == nil)
                .foregroundStyle(anchor == nil ? Color.hsSecondary : Color.hsText)
                .listRowBackground(Color.hsPanel)
            }
            .scrollContentBackground(.hidden).background(Color.hsNight)
            .navigationTitle(Text("sky.constellationList"))
            .toolbar { ToolbarItem(placement: .confirmationAction) { Button("sky.done") { dismiss() } } }
        }.preferredColorScheme(.dark).tint(Color.hsDiscovery)
    }
}
