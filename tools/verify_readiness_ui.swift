import AppKit
import SwiftUI

/// Runs on the macOS builder using the app's actual copy view and the built
/// iPhone app's compiled localization tables. No live sensor state is faked.
@main
struct VerifyReadinessUI {
    @MainActor
    static func main() throws {
        let appURL = URL(fileURLWithPath: CommandLine.arguments[1])
        let outputURL = URL(fileURLWithPath: CommandLine.arguments[2])
        try FileManager.default.createDirectory(at: outputURL, withIntermediateDirectories: true)

        // Diagnostic only: show how the previous expression becomes a format.
        let state = DirectionReadiness.calibrating
        let previousKey = LocalizedStringKey("readiness.\(state.rawValue).title")
        let previousRepresentation = Mirror(reflecting: previousKey).children
            .first(where: { $0.label == "key" })?.value
        print("Previous SwiftUI key representation: \(String(describing: previousRepresentation))")

        for language in ["ja", "en"] {
            guard let bundle = Bundle(url: appURL.appendingPathComponent("\(language).lproj")) else {
                fatalError("Missing built localization bundle: \(language)")
            }
            for state in DirectionReadiness.allCases {
                let copy = DirectionStatusCopy(state: state, bundle: bundle)
                precondition(!copy.title.isEmpty && !copy.title.hasPrefix("readiness."))
                precondition(!copy.detail.isEmpty && !copy.detail.hasPrefix("readiness."))
            }
            let calibrationCopy = DirectionStatusCopy(state: .calibrating, bundle: bundle)
            precondition(calibrationCopy.title == (
                language == "ja" ? "方角の調整が必要です" : "Direction needs adjusting"
            ))
            print("\(language): all \(DirectionReadiness.allCases.count) readiness titles and bodies resolved")

            let content = VStack(alignment: .leading, spacing: 18) {
                ForEach([DirectionReadiness.checkingDirection, .calibrating, .ready], id: \.rawValue) { state in
                    HStack(alignment: .top, spacing: 10) {
                        Image(systemName: state.canUseDirection ? "checkmark.circle.fill" : "info.circle")
                            .foregroundStyle(Color.hsDiscovery)
                        DirectionStatusCopy(state: state, bundle: bundle)
                    }
                    .padding(12)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .nightPanel()
                }
            }
            .padding(16)
            .frame(width: 360)
            .foregroundStyle(Color.hsText)
            .background(Color.hsNight)
            .environment(\.locale, Locale(identifier: language))
            let renderer = ImageRenderer(content: content)
            renderer.scale = 2
            guard let image = renderer.cgImage,
                  let data = NSBitmapImageRep(cgImage: image).representation(using: .png, properties: [:]) else {
                fatalError("Could not render production readiness copy")
            }
            try data.write(to: outputURL.appendingPathComponent("readiness-\(language).png"))
        }
    }
}
