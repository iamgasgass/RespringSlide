import SwiftUI

/// Ported code-for-code from OldSafari's `OldOSTitleBar` (SafariControls.swift)
/// and OldOS' `generic_title_bar`: the bar gradient, the 1pt bottom hairline,
/// the top inner-shadow glossy highlight, and the Helvetica Neue Bold 22 title
/// with its emboss + hard `titleBarTitleShadow`.
///
/// `topInset` lets the bar extend full-screen up under the status bar / Dynamic
/// Island on modern iOS. Crucially, the glossy OldSafari chrome (full gradient
/// + sheen + hairlines) is rendered on the visible bottom 60pt (OldSafari's bar
/// height), while the status-bar area is filled with the gradient's light top
/// colour — so the gloss shows on the bar, not hidden under the status bar.
struct OldOSTitleBar: View {
    let title: String
    let theme: OldOSSafariTheme
    var topInset: CGFloat = 0

    var body: some View {
        ZStack(alignment: .bottom) {
            // Status-bar extension: the gradient's top (lightest) colour.
            (theme.barGradient.first?.color ?? .black)

            // The visible 60pt OldSafari bar: full glossy gradient + sheen.
            ZStack(alignment: .top) {
                LinearGradient(oldOS: theme.barGradient)
                    .oldOSInnerShadowBottom(color: theme.barHighlight, radius: 0.025)

                // Hairlines at the top of the visible bar (white over black).
                VStack(spacing: 0) {
                    Rectangle().fill(Color.white.opacity(0.22)).frame(height: 1)
                    Rectangle().fill(Color.black.opacity(0.6)).frame(height: 1)
                    Spacer(minLength: 0)
                }

                Text(title)
                    .font(OldOSFont.bold(22))
                    .foregroundColor(theme.titleBarTitle)
                    // Emboss (OldOS `ps_innerShadow(white, …0.07)`) + hard shadow.
                    .shadow(color: theme.titleBarTitleEmboss, radius: 0, x: 0, y: 1)
                    .shadow(color: theme.titleBarTitleShadow, radius: 0, x: 0, y: -1)
                    .lineLimit(1)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            .frame(height: 60)
            .oldOSBorder(width: 1, edges: [.bottom], color: theme.barHairline)
            .oldOSBorder(width: 1, edges: [.bottom], color: Color.black.opacity(0.7))
        }
        .frame(height: topInset + 60)
        .oldOSBorder(width: 1, edges: [.top], color: Color.white.opacity(0.22))
    }
}
