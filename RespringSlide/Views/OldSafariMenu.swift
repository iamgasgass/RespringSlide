import SwiftUI
import UIKit

// MARK: - Panel pointer (verbatim from the OldSafari project)

/// Little triangle under the history panel, pointing at the control that
/// opened it. Copied 1:1 from OldSafari's `OldOSPanelPointer`.
struct OldOSPanelPointer: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.minX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.midX, y: rect.maxY))
        path.closeSubpath()
        return path
    }
}

// MARK: - iOS 6 "…" toolbar button (OldSafari chrome)

/// The top-right "…" button in OldOS mode, drawn with the OldSafari iOS 6
/// sheet-metal button treatment (`OldOSRectangleButton` look: recessed bevel,
/// hard dark glyph shadow, white bottom highlight) instead of Liquid Glass.
struct OldOSEllipsisButton: View {
    var action: () -> Void

    var body: some View {
        Button {
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            action()
        } label: {
            Text("•••")
                .font(OldOSFont.bold(15))
                .tracking(1)
                .foregroundColor(.white)
                .shadow(color: .black.opacity(0.75), radius: 1, x: 0, y: -0.25)
                .frame(width: 52, height: 32)
                .oldOSInnerShadowBackground(
                    RoundedRectangle(cornerRadius: 5.5),
                    oldOSButtonGradient(.black),
                    radius: 0.8,
                    offset: CGPoint(x: 0, y: 0.6),
                    intensity: 0.7
                )
                .shadow(color: .white.opacity(0.28), radius: 0, x: 0, y: 0.8)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - iOS 6 dropdown (OldSafari history-panel style)

/// A dropdown styled exactly like OldSafari's back/forward history preview
/// panel (`SafariHistoryPreviewPanel`): the dark 2012 sheet-metal body, a
/// header strip, hairline-separated rows and a pointer triangle — here the
/// pointer sits at the top, aimed up at the "…" button that opened it.
struct OldOSThemeMenuPanel: View {
    let current: AppTheme
    let onSelect: (AppTheme) -> Void
    let onDismiss: () -> Void

    private let theme = OldOSSafariTheme.standard
    private let rowHeight: CGFloat = 46
    private let headerHeight: CGFloat = 30
    private let panelWidth: CGFloat = 248

    var body: some View {
        GeometryReader { geometry in
            let topInset = max(OldOSScreen.safeArea.top, 20)
            // Anchor the panel under the top-right "…" button.
            let right = geometry.size.width - 18
            let left = max(right - panelWidth, 12)
            let pointerX = right - 26 // roughly the button centre
            let top = topInset + 8 + 32 + 6 // below the button

            ZStack(alignment: .topLeading) {
                theme.scrim.opacity(0.4)
                    .ignoresSafeArea()
                    .contentShape(Rectangle())
                    .onTapGesture { onDismiss() }

                VStack(spacing: 0) {
                    // Pointer at the top, aimed up at the button.
                    OldOSPanelPointer()
                        .rotation(.degrees(180))
                        .fill(LinearGradient(oldOS: theme.shareStrip))
                        .frame(width: 20, height: 9)
                        .offset(x: pointerX - left - 10)
                        .frame(width: panelWidth, alignment: .leading)

                    panelBody
                }
                .frame(width: panelWidth)
                .offset(x: left, y: top)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        }
        .ignoresSafeArea()
    }

    private var panelBody: some View {
        VStack(spacing: 0) {
            ZStack {
                Rectangle()
                    .fill(LinearGradient(oldOS: theme.shareStrip))
                    .oldOSInnerShadowBottom(color: Color.white.opacity(0.98), radius: 0.1)
                Text("Aspetto")
                    .font(OldOSFont.bold(13.25))
                    .foregroundColor(theme.panelTitleText)
                    .shadow(color: theme.panelTitleShadow, radius: 0, x: 0, y: theme.panelTitleShadowY)
            }
            .frame(height: headerHeight)

            ForEach(Array(AppTheme.allCases.enumerated()), id: \.element.id) { index, item in
                row(item, isLast: index == AppTheme.allCases.count - 1)
            }
        }
        .background(LinearGradient(oldOS: theme.shareBody))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .oldOSAddBorder(
            LinearGradient(oldOS: theme.shareButtonOuterStroke),
            width: 0.5,
            cornerRadius: 12
        )
        .shadow(color: Color.black.opacity(0.5), radius: 14, x: 0, y: 5)
    }

    private func row(_ item: AppTheme, isLast: Bool) -> some View {
        Button {
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            onSelect(item)
        } label: {
            VStack(spacing: 0) {
                HStack(spacing: 10) {
                    Image(systemName: item.symbol)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(Color.white.opacity(0.5))
                        .frame(width: 20)

                    Text(item.title)
                        .font(OldOSFont.bold(16))
                        .foregroundColor(.white)
                        .lineLimit(1)

                    Spacer(minLength: 0)

                    Image(systemName: item == current ? "checkmark" : "chevron.right")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(Color.white.opacity(item == current ? 0.95 : 0.35))
                }
                .padding([.leading, .trailing], 14)
                .frame(height: rowHeight - 1)

                Rectangle()
                    .fill(Color.white.opacity(isLast ? 0 : 0.09))
                    .frame(height: 1)
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

// MARK: - iOS 6 alert (OldOS UIAlertView style)

/// A modal styled exactly like the iOS 6 `UIAlertView` as recreated in OldOS:
/// a centred rounded "aluminium" panel with a glossy top sheen, white bold
/// title, white message and glossy two-tone buttons, over a dimmed backdrop.
struct OldOSAlertView: View {
    let title: String
    let message: String
    let cancelTitle: String
    let confirmTitle: String
    let onCancel: () -> Void
    let onConfirm: () -> Void

    var body: some View {
        ZStack {
            Color.black.opacity(0.55)
                .ignoresSafeArea()

            VStack(spacing: 0) {
                VStack(spacing: 9) {
                    Text(title)
                        .font(OldOSFont.bold(17))
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                        .shadow(color: .black.opacity(0.75), radius: 0, x: 0, y: -0.75)

                    Text(message)
                        .font(OldOSFont.regular(13))
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)
                        .shadow(color: .black.opacity(0.7), radius: 0, x: 0, y: -0.75)
                }
                .padding(.horizontal, 16)
                .padding(.top, 16)
                .padding(.bottom, 14)

                // Button row.
                HStack(spacing: 8) {
                    alertButton(cancelTitle, type: .blueGray, action: onCancel)
                    alertButton(confirmTitle, type: .blue, action: onConfirm)
                }
                .padding(.horizontal, 10)
                .padding(.bottom, 12)
            }
            .frame(width: 276)
            .background(
                RoundedRectangle(cornerRadius: 13)
                    .fill(LinearGradient(oldOS: [
                        OldOSStop(.oldOS(120, 128, 142), 0),
                        OldOSStop(.oldOS(92, 101, 117), 0.08),
                        OldOSStop(.oldOS(64, 72, 88), 0.5),
                        OldOSStop(.oldOS(52, 60, 74), 0.5),
                        OldOSStop(.oldOS(40, 46, 58), 1)
                    ]))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 13)
                    .fill(LinearGradient(colors: [Color.white.opacity(0.35), .clear],
                                         startPoint: .top, endPoint: .center))
                    .padding(1)
                    .allowsHitTesting(false)
            )
            .overlay(RoundedRectangle(cornerRadius: 13).strokeBorder(Color.black.opacity(0.6), lineWidth: 1))
            .overlay(RoundedRectangle(cornerRadius: 12).strokeBorder(Color.white.opacity(0.18), lineWidth: 0.75).padding(1))
            .shadow(color: .black.opacity(0.6), radius: 20, x: 0, y: 8)
        }
    }

    private func alertButton(_ text: String, type: OldOSButtonType, action: @escaping () -> Void) -> some View {
        Button {
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            action()
        } label: {
            Text(text)
                .font(OldOSFont.bold(16))
                .foregroundColor(.white)
                .shadow(color: .black.opacity(0.75), radius: 0, x: 0, y: -0.5)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
                .frame(maxWidth: .infinity)
                .frame(height: 44)
                .oldOSInnerShadowBackground(
                    RoundedRectangle(cornerRadius: 8),
                    oldOSButtonGradient(type),
                    radius: 0.8,
                    offset: CGPoint(x: 0, y: 0.6),
                    intensity: 0.7
                )
                .overlay(RoundedRectangle(cornerRadius: 8).strokeBorder(Color.black.opacity(0.5), lineWidth: 0.75))
                .shadow(color: .white.opacity(0.22), radius: 0, x: 0, y: 0.8)
        }
        .buttonStyle(.plain)
    }
}
