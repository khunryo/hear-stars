import SwiftUI

struct GuidanceModePicker: View {
    let selection: GuidanceMode
    let onSelect: (GuidanceMode) -> Void

    var body: some View {
        HStack(spacing: 8) {
            ForEach(GuidanceMode.allCases) { mode in
                Button {
                    onSelect(mode)
                } label: {
                    VStack(spacing: 5) {
                        Image(systemName: mode.systemImage)
                            .font(.system(size: 17, weight: .light))
                        Text(LocalizedStringKey(mode.titleKey))
                            .font(.caption.weight(.medium))
                            .lineLimit(1)
                            .minimumScaleFactor(0.75)
                    }
                    .frame(maxWidth: .infinity, minHeight: 52)
                    .foregroundStyle(mode == selection ? Color.hsDiscovery : Color.hsSecondary)
                    .background(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .fill(mode == selection ? Color.hsGuide.opacity(0.13) : Color.clear)
                    )
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityAddTraits(mode == selection ? .isSelected : [])
            }
        }
        .padding(6)
        .nightPanel()
        .accessibilityElement(children: .contain)
        .accessibilityLabel(Text("mode.group"))
    }
}

