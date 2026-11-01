import SwiftUI
import UIKit

/// The Settings section rendered in classic iOS 6 / OldOS style (used when the
/// OldOS skin is active), drawn with the OldSafari / OldOS palette: a blue-grey
/// title bar, pinstripe grouped background, white rounded cards, hairline rows,
/// iOS 6 switches and checkmark selection — like the user's other OldOS apps.
struct OldOSSettingsView: View {
    @EnvironmentObject private var settings: AppSettings

    private let theme = OldOSSafariTheme.standard

    private var appVersion: String {
        let v = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
        let b = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
        return "\(v) (\(b))"
    }

    var body: some View {
        VStack(spacing: 0) {
            titleBar

            ZStack {
                theme.groupedBackground.ignoresSafeArea()
                OldOSPinstripeBackground(line: theme.groupedPinstripe)
                    .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 0) {
                        appearanceSection
                        interfaceSection
                        respringSection
                        resetSection
                        infoSection
                    }
                    .padding(.vertical, 14)
                }
                .scrollIndicators(.hidden)
            }
        }
        .background(theme.groupedBackground)
    }

    // MARK: Title bar

    private var titleBar: some View {
        ZStack {
            LinearGradient(oldOS: theme.barGradient)
                .oldOSBorder(width: 1, edges: [.bottom], color: theme.barHairline)
                .oldOSInnerShadowBottom(color: theme.barHighlight, radius: 0.025)

            Text("Impostazioni")
                .font(OldOSFont.bold(20))
                .foregroundColor(theme.titleBarTitle)
                .shadow(color: theme.titleBarTitleShadow, radius: 0, x: 0, y: -1)
        }
        .frame(height: 44)
    }

    // MARK: Sections

    private var appearanceSection: some View {
        section(header: "ASPETTO", footer: "“Sistema” segue iOS; “Chiaro” e “Scuro” forzano l'aspetto dell'app.") {
            ForEach(Array(AppAppearance.allCases.enumerated()), id: \.element.id) { index, option in
                checkRow(
                    title: option.title,
                    selected: settings.appearance == option,
                    isLast: index == AppAppearance.allCases.count - 1
                ) {
                    settings.tap()
                    settings.appearance = option
                }
            }
        }
    }

    private var interfaceSection: some View {
        section(header: "INTERFACCIA", footer: settings.skin == .oldOS
                ? "OldOS: UI iOS 6 in tutta l'app."
                : "Liquid Glass: l'interfaccia nativa di iOS 27.") {
            ForEach(Array(AppTheme.allCases.enumerated()), id: \.element.id) { index, skin in
                checkRow(
                    title: skin.title,
                    selected: settings.skin == skin,
                    isLast: index == AppTheme.allCases.count - 1
                ) {
                    settings.tap()
                    settings.skin = skin
                }
            }
        }
    }

    private var respringSection: some View {
        section(header: "RESPRING", footer: "Quanto lontano trascinare per attivare il respring. Con la conferma, dopo lo slider appare un avviso.") {
            toggleRow(title: "Chiedi conferma", isOn: $settings.requireConfirmation, isLast: false)
            toggleRow(title: "Feedback aptico", isOn: $settings.haptics, isLast: false)
            sliderRow(isLast: true)
        }
    }

    private var resetSection: some View {
        section(header: nil, footer: nil) {
            Button {
                settings.tap(.medium)
                settings.requireConfirmation = true
                settings.haptics = true
                settings.threshold = 0.84
                settings.appearance = .system
                settings.skin = .liquidGlass
            } label: {
                HStack {
                    Spacer()
                    Text("Ripristina impostazioni")
                        .font(OldOSFont.bold(17))
                        .foregroundColor(.oldOS(189, 20, 33))
                    Spacer()
                }
                .frame(height: 44)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
        }
    }

    private var infoSection: some View {
        section(header: "INFORMAZIONI", footer: "La tecnica di respring è sperimentale (WebKit): può bloccare WebKit, riavviare SpringBoard o non fare nulla, e non è garantita. Salva il tuo lavoro. Non è un'API supportata da Apple.") {
            valueRow(title: "Versione", value: appVersion, isLast: false)
            valueRow(title: "Autore", value: "iamgasgass", isLast: true)
        }
    }

    // MARK: Building blocks

    @ViewBuilder
    private func section<Content: View>(header: String?, footer: String?, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            if let header {
                Text(header)
                    .font(OldOSFont.bold(13))
                    .foregroundColor(theme.sectionHeader)
                    .shadow(color: .white.opacity(0.6), radius: 0, x: 0, y: 1)
                    .padding(.leading, 26)
                    .padding(.bottom, 6)
            }

            VStack(spacing: 0) { content() }
                .background(theme.cardFill)
                .clipShape(RoundedRectangle(cornerRadius: 10))
                .oldOSStrokeRoundedRectangle(10, theme.cardStroke, lineWidth: 1)
                .padding(.horizontal, 14)

            if let footer {
                Text(footer)
                    .font(OldOSFont.regular(12))
                    .foregroundColor(theme.sectionHeader.opacity(0.9))
                    .shadow(color: .white.opacity(0.5), radius: 0, x: 0, y: 1)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.horizontal, 26)
                    .padding(.top, 6)
            }
        }
        .padding(.bottom, 22)
    }

    private func rowSeparator(_ isLast: Bool) -> some View {
        Rectangle()
            .fill(theme.listSeparator)
            .frame(height: isLast ? 0 : 1)
    }

    private func checkRow(title: String, selected: Bool, isLast: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 0) {
                HStack {
                    Text(title)
                        .font(OldOSFont.bold(17))
                        .foregroundColor(theme.listRowText)
                    Spacer()
                    if selected {
                        Image(systemName: "checkmark")
                            .font(.system(size: 15, weight: .bold))
                            .foregroundColor(.oldOS(62, 83, 131))
                    }
                }
                .padding(.horizontal, 14)
                .frame(height: 44)
                rowSeparator(isLast)
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    private func toggleRow(title: String, isOn: Binding<Bool>, isLast: Bool) -> some View {
        VStack(spacing: 0) {
            HStack {
                Text(title)
                    .font(OldOSFont.bold(17))
                    .foregroundColor(theme.listRowText)
                Spacer()
                OldOSToggle(isOn: isOn)
            }
            .padding(.horizontal, 14)
            .frame(height: 44)
            rowSeparator(isLast)
        }
    }

    private func sliderRow(isLast: Bool) -> some View {
        VStack(spacing: 2) {
            HStack {
                Text("Soglia di scorrimento")
                    .font(OldOSFont.bold(17))
                    .foregroundColor(theme.listRowText)
                Spacer()
                Text("\(Int(settings.threshold * 100))%")
                    .font(OldOSFont.regular(15))
                    .foregroundColor(theme.listRowDetail)
                    .monospacedDigit()
            }
            Slider(value: $settings.threshold, in: 0.6...0.95, step: 0.01)
                .tint(.oldOS(46, 123, 229))
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 8)
    }

    private func valueRow(title: String, value: String, isLast: Bool) -> some View {
        VStack(spacing: 0) {
            HStack {
                Text(title)
                    .font(OldOSFont.bold(17))
                    .foregroundColor(theme.listRowText)
                Spacer()
                Text(value)
                    .font(OldOSFont.regular(16))
                    .foregroundColor(theme.listRowDetail)
            }
            .padding(.horizontal, 14)
            .frame(height: 44)
            rowSeparator(isLast)
        }
    }
}

// MARK: - iOS 6 switch

/// A classic iOS 6 toggle: glossy track (blue when on, grey when off) with a
/// white knob, drawn from the OldSafari palette.
struct OldOSToggle: View {
    @Binding var isOn: Bool

    private let width: CGFloat = 51
    private let height: CGFloat = 31

    var body: some View {
        ZStack(alignment: isOn ? .trailing : .leading) {
            Capsule()
                .fill(isOn
                      ? LinearGradient(oldOS: [OldOSStop(.oldOS(92, 170, 236), 0), OldOSStop(.oldOS(42, 128, 226), 1)])
                      : LinearGradient(oldOS: [OldOSStop(.oldOS(228, 228, 230), 0), OldOSStop(.oldOS(206, 206, 208), 1)]))
                .overlay(Capsule().strokeBorder(Color.black.opacity(0.22), lineWidth: 1))
                .frame(width: width, height: height)

            Circle()
                .fill(LinearGradient(oldOS: [OldOSStop(.white, 0), OldOSStop(.oldOS(236, 236, 238), 1)]))
                .overlay(Circle().strokeBorder(Color.black.opacity(0.28), lineWidth: 0.75))
                .shadow(color: .black.opacity(0.35), radius: 1, x: 0, y: 1)
                .frame(width: height - 3, height: height - 3)
                .padding(1.5)
        }
        .frame(width: width, height: height)
        .contentShape(Rectangle())
        .onTapGesture {
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            withAnimation(.spring(response: 0.25, dampingFraction: 0.8)) { isOn.toggle() }
        }
        .accessibilityAddTraits(.isButton)
        .accessibilityValue(isOn ? "Attivo" : "Disattivo")
    }
}
