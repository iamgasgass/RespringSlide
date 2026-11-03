import SwiftUI

/// Ported code-for-code from OldSafari's title bar (SafariControls.swift) and
/// OldOS' `generic_title_bar`: the bar gradient, the top inner-shadow glossy
/// highlight, the 1pt bottom hairline and the Helvetica Neue Bold 22 title
/// with its emboss + hard `titleBarTitleShadow`.
///
/// Full screen exactly like OldSafari: ONE gradient runs from the top of the
/// screen (behind the status bar / Dynamic Island) to the bottom of the bar,
/// so the status-bar area and the bar are a single piece of chrome, with no
/// band or line between them. The glossy highlight and the title sit on the
/// visible 60pt bar below the status bar.
struct OldOSTitleBar: View {
    let title: String
    let theme: OldOSSafariTheme
    var topInset: CGFloat = 0

    var body: some View {
        VStack(spacing: 0) {
            Color.clear.frame(height: topInset)
            Text(title)
                .font(OldOSFont.bold(22))
                .foregroundColor(theme.titleBarTitle)
                // Emboss (OldOS `ps_innerShadow(white, …0.07)`) + hard shadow.
                .shadow(color: theme.titleBarTitleEmboss, radius: 0, x: 0, y: 1)
                .shadow(color: theme.titleBarTitleShadow, radius: 0, x: 0, y: -1)
                .lineLimit(1)
                .frame(maxWidth: .infinity)
                .frame(height: 60)
        }
        .background(
            VStack(spacing: 0) {
                Color.clear.frame(height: topInset)
                Color.clear
                    .frame(height: 60)
                    .oldOSInnerShadowBottom(color: theme.barHighlight, radius: 0.025)
            }
            .background(LinearGradient(oldOS: theme.barGradient))
        )
        .oldOSBorder(width: 1, edges: [.bottom], color: theme.barHairline)
    }
}
