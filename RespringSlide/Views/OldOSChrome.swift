import SwiftUI

/// Ported code-for-code from OldSafari's `OldOSTitleBar` (SafariControls.swift)
/// and its full-screen chrome (SafariRootView.swift `chrome`):
///
/// - the 60pt bar draws its OWN `LinearGradient(oldOS: theme.barGradient)`,
///   so the glossy split of the gradient (the 0.49 stop) falls in the middle
///   of the bar exactly like OldSafari, with the 1pt `barHairline` at the
///   bottom and the `oldOSInnerShadowBottom(barHighlight, 0.025)` sheen at
///   the top;
/// - behind it, the chrome background is another `barGradient` running
///   from the top of the screen (status bar / Dynamic Island) down to the
///   bottom of the bar, as in OldSafari's `chrome.background`;
/// - Helvetica Neue Bold 22 title with the hard `titleBarTitleShadow`.
struct OldOSTitleBar: View {
    let title: String
    let theme: OldOSSafariTheme
    var topInset: CGFloat = 0

    var body: some View {
        VStack(spacing: 0) {
            Color.clear.frame(height: topInset)

            // OldSafari `OldOSTitleBar`.
            ZStack {
                LinearGradient(oldOS: theme.barGradient)
                    .oldOSBorder(width: 1, edges: [.bottom], color: theme.barHairline)
                    .oldOSInnerShadowBottom(color: theme.barHighlight, radius: 0.025)

                Text(title)
                    .font(OldOSFont.bold(22))
                    .foregroundColor(theme.titleBarTitle)
                    .shadow(color: theme.titleBarTitleShadow, radius: 0, x: 0, y: -1)
                    .lineLimit(1)
                    .padding([.leading, .trailing], 74)
            }
            .frame(height: 60)
        }
        // OldSafari `chrome.background`: the bar gradient behind the status bar.
        .background(
            LinearGradient(oldOS: theme.barGradient)
                .ignoresSafeArea(edges: .top)
        )
    }
}
