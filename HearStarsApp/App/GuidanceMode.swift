import Foundation

enum GuidanceMode: String, CaseIterable, Identifiable {
    case sound
    case haptic
    case visual

    var id: Self { self }

    var titleKey: String {
        switch self {
        case .sound: return "mode.sound"
        case .haptic: return "mode.haptic"
        case .visual: return "mode.visual"
        }
    }

    var systemImage: String {
        switch self {
        case .sound: return "wave.3.right"
        case .haptic: return "circle.dotted"
        case .visual: return "eye"
        }
    }
}

enum AppRoute: Equatable {
    case picker
    case safety
    case calibration
    case finder
    case discovery
    case constellation
}

enum L10n {
    static func string(_ key: String, bundle: Bundle = .main) -> String {
        NSLocalizedString(key, bundle: bundle, comment: "")
    }

    static func format(_ key: String, _ arguments: CVarArg...) -> String {
        String(format: string(key), locale: .current, arguments: arguments)
    }
}
