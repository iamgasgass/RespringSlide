import SwiftUI

/// Hosts the two skins and the shared respring engine, and overlays the
/// native Liquid Glass "…" picker (top-right) that switches between them.
///
/// The engine (`RespringPayloadView`) lives here so both skins trigger the
/// identical behaviour: slide → confirm → run.
struct RootPowerView: View {
    @StateObject private var themeStore = AppThemeStore()

    @State private var isRunning = false
    @State private var engineEnabled = false

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            // Active skin.
            Group {
                switch themeStore.theme {
                case .liquidGlass:
                    LiquidGlassPowerOffView(isRunning: isRunning, onArmed: arm)
                case .oldOS:
                    OldOSPowerOffView(isRunning: isRunning, onArmed: arm)
                }
            }
            .transition(.opacity)

            // The embedded engine sits on top once armed.
            if engineEnabled {
                RespringPayloadView()
                    .ignoresSafeArea()
                    .transition(.opacity)
                    .accessibilityHidden(true)
            }

            // The "…" picker — native Liquid Glass, exactly like the X button.
            themePicker
        }
        .statusBarHidden(true)
        .preferredColorScheme(.dark)
        .animation(.easeInOut(duration: 0.28), value: themeStore.theme)
    }

    private var themePicker: some View {
        VStack {
            HStack {
                Spacer()
                Menu {
                    Picker("Aspetto", selection: pickerBinding) {
                        ForEach(AppTheme.allCases) { theme in
                            Label("\(theme.title) — \(theme.subtitle)", systemImage: theme.symbol)
                                .tag(theme)
                        }
                    }
                } label: {
                    Image(systemName: "ellipsis")
                        .font(.system(size: 22, weight: .semibold))
                        .foregroundStyle(.white.opacity(0.96))
                        .frame(width: 48, height: 48)
                        // Identical native Liquid Glass material as the X button.
                        .glassEffect(.regular.interactive(), in: Circle())
                }
                .menuStyle(.button)
                .buttonStyle(.plain)
                .disabled(isRunning)
                .opacity(isRunning ? 0.35 : 1)
                .accessibilityLabel("Scegli l'aspetto")
                .padding(.trailing, 18)
            }
            .padding(.top, 8)
            Spacer()
        }
    }

    private var pickerBinding: Binding<AppTheme> {
        Binding(
            get: { themeStore.theme },
            set: { themeStore.select($0) }
        )
    }

    private func arm() {
        isRunning = true
        withAnimation(.easeInOut(duration: 0.25)) {
            engineEnabled = true
        }
    }
}

#Preview {
    RootPowerView()
}
