import SwiftUI

/// The two skins the app can present. The visuals differ completely, the
/// behaviour (slide → confirm → respring) is identical.
enum AppTheme: String, CaseIterable, Identifiable {
    /// The current app: native SwiftUI Liquid Glass (iOS 26+).
    case liquidGlass
    /// iOS 6 recreation, reusing the OldSafari / OldOS appearance kit:
    /// graphite palette, dark mode, full-screen on modern devices, and the
    /// classic iOS 6 "slide to power off" control.
    case oldOS

    var id: String { rawValue }

    /// Label shown in the "…" picker.
    var title: String {
        switch self {
        case .liquidGlass: return "Liquid Glass"
        case .oldOS:       return "OldOS"
        }
    }

    /// Short description shown under the label in the picker.
    var subtitle: String {
        switch self {
        case .liquidGlass: return "App attuale"
        case .oldOS:       return "UI iOS 6 (OldSafari)"
        }
    }

    var symbol: String {
        switch self {
        case .liquidGlass: return "circle.hexagongrid.fill"
        case .oldOS:       return "clock.arrow.circlepath"
        }
    }
}

/// Persists the chosen theme across launches.
@MainActor
final class AppThemeStore: ObservableObject {
    @AppStorage("respringslide.theme") private var storedRaw: String = AppTheme.liquidGlass.rawValue

    @Published var theme: AppTheme = .liquidGlass

    init() {
        theme = AppTheme(rawValue: storedRaw) ?? .liquidGlass
    }

    func select(_ newTheme: AppTheme) {
        theme = newTheme
        storedRaw = newTheme.rawValue
    }
}
