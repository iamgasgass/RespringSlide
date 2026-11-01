import SwiftUI
import UIKit

/// The "OldOS" skin. The slider is ported code-for-code from OldOS'
/// `lock_footer` (OldOS/LockScreen.swift) — the same dark rounded track with
/// its `[83…143]` gradient border, the same metallic knob with the `⮕` glyph,
/// and the same `gradientForeground` shine on the label (here reading
/// "Scorri per respring"). The knob carries the same gradient border as the
/// track so the bubble matches the slider.
struct OldOSPowerOffView: View {
    let isRunning: Bool
    let onArmed: () -> Void

    @EnvironmentObject private var settings: AppSettings

    @State private var sliderOffset: CGFloat = 0
    @State private var showingAlert = false

    var body: some View {
        GeometryReader { geometry in
            let w = geometry.size.width
            let trackWidth = min(w - 44, 560)
            let trackHeight: CGFloat = 86

            ZStack {
                Color.black.ignoresSafeArea()
                RadialGradient(
                    colors: [Color.oldOS(42, 44, 48).opacity(0.55), .clear],
                    center: .top, startRadius: 8, endRadius: geometry.size.height * 0.8
                )
                .ignoresSafeArea()

                VStack(spacing: 0) {
                    respringIndicator
                        .padding(.top, 8)

                    slideToPowerOff(width: trackWidth, height: trackHeight)
                        .padding(.top, 26)

                    Spacer(minLength: 0)

                    cancelButton(width: trackWidth)
                        .padding(.bottom, 20)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .overlay {
                if showingAlert {
                    OldOSAlertView(
                        title: "Avviare il respring?",
                        message: "La tecnica può bloccare WebKit o riavviare SpringBoard, ma non è garantita su ogni versione di iOS. Salva prima il tuo lavoro.",
                        cancelTitle: "Annulla",
                        confirmTitle: "Avvia respring",
                        onCancel: {
                            showingAlert = false
                            resetSlider()
                        },
                        onConfirm: {
                            showingAlert = false
                            onArmed()
                        }
                    )
                    .transition(.opacity)
                }
            }
        }
    }

    // MARK: - Top indicator ("the whole bubble" in iOS 6 gloss)

    private var respringIndicator: some View {
        HStack(spacing: 7) {
            Image(systemName: "arrow.clockwise")
                .font(OldOSFont.bold(13))
                .foregroundColor(.white)
            Text("Respring")
                .font(OldOSFont.bold(15))
                .foregroundColor(.white)
        }
        .shadow(color: .black.opacity(0.65), radius: 0, x: 0, y: -0.9)
        .padding(.horizontal, 20)
        .frame(height: 38)
        .background(iOS6GlossCapsule(type: .black))
    }

    // MARK: - Slide to power off (ported from OldOS `lock_footer`)

    /// The OldOS track border/knob gradient, `[83…143]`, shared by both so the
    /// bubble matches the slider.
    private var oldOSBorderGradient: LinearGradient {
        LinearGradient(oldOS: [
            OldOSStop(.oldOS(83, 83, 83), 0),
            OldOSStop(.oldOS(143, 143, 143), 1)
        ])
    }

    private func slideToPowerOff(width: CGFloat, height: CGFloat) -> some View {
        let knobWidth: CGFloat = 75
        let inset: CGFloat = 6
        let travel = max(0, width - knobWidth - inset * 2)

        return ZStack(alignment: .leading) {
            // OldOS track: dark rounded rectangle with the [83…143] stroke.
            RoundedRectangle(cornerRadius: 12)
                .fill(LinearGradient(oldOS: [
                    OldOSStop(.oldOS(3, 3, 3), 0),
                    OldOSStop(.oldOS(21, 21, 21), 0.5),
                    OldOSStop(.oldOS(32, 32, 32), 1)
                ]))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(oldOSBorderGradient, lineWidth: 0.5)
                )

            // OldOS shine label, reading "Scorri per respring".
            Group {
                if isRunning {
                    Text("Respring in corso")
                        .font(.custom("Helvetica Neue", fixedSize: 25))
                        .foregroundColor(.white.opacity(0.85))
                        .lineLimit(1)
                } else {
                    OldOSSlideShineLabel(text: "Scorri per respring")
                }
            }
            .frame(width: width, height: height)
            .allowsHitTesting(false)

            // OldOS metallic knob (bubble) with the ⮕ glyph, same border.
            oldOSKnob(width: knobWidth, height: height - inset * 2)
                .padding(inset)
                .offset(x: sliderOffset)
                .gesture(
                    DragGesture(minimumDistance: 0)
                        .onChanged { value in
                            guard !isRunning else { return }
                            sliderOffset = min(max(value.translation.width, 0), travel)
                        }
                        .onEnded { _ in
                            guard !isRunning else { return }
                            if travel > 0 && sliderOffset >= travel * CGFloat(settings.threshold) {
                                settings.tap(.medium)
                                withAnimation(.spring(response: 0.28, dampingFraction: 0.88)) {
                                    sliderOffset = travel
                                }
                                armOrConfirm()
                            } else {
                                withAnimation(.spring(response: 0.42, dampingFraction: 0.76)) {
                                    sliderOffset = 0
                                }
                            }
                        }
                )
                .accessibilityLabel("Scorri per respring")
                .accessibilityHint("Trascina fino all'estremità destra per avviare il respring")
        }
        .frame(width: width, height: height)
    }

    /// OldOS `lock_footer` knob, ported: metallic base + top gloss half + ⮕
    /// glyph, with the shared [83…143] border so the bubble matches the slider.
    private func oldOSKnob(width: CGFloat, height: CGFloat) -> some View {
        ZStack {
            ZStack(alignment: .topLeading) {
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(LinearGradient(oldOS: [
                        OldOSStop(.oldOS(208, 208, 208), 0),
                        OldOSStop(.oldOS(168, 168, 168), 1)
                    ]))
                GeometryReader { geo in
                    Rectangle()
                        .fill(LinearGradient(oldOS: [
                            OldOSStop(.oldOS(243, 243, 243), 0),
                            OldOSStop(.oldOS(225, 225, 225), 1)
                        ]))
                        .frame(width: width, height: geo.size.height / 2, alignment: .top)
                        .clipped()
                }
            }
            Text("⮕")
                .font(.custom("Helvetica Neue", fixedSize: 39))
                .foregroundStyle(LinearGradient(oldOS: [
                    OldOSStop(.oldOS(166, 166, 166), 0.5),
                    OldOSStop(.oldOS(134, 134, 134), 0.5)
                ]))
                .shadow(color: .white.opacity(0.4), radius: 0, x: 0, y: 0.75)
        }
        .frame(width: width, height: height)
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .stroke(oldOSBorderGradient, lineWidth: 0.5)
        )
    }

    // MARK: - Cancel

    private func cancelButton(width: CGFloat) -> some View {
        Button {
            settings.tap()
            resetSlider()
        } label: {
            Text("Annulla")
                .font(OldOSFont.bold(20))
                .foregroundColor(.white)
                .shadow(color: .black.opacity(0.7), radius: 0, x: 0, y: -1)
                .frame(maxWidth: .infinity)
                .frame(height: 50)
                .background(iOS6GlossButton(type: .black))
        }
        .buttonStyle(.plain)
        .frame(width: width)
        .disabled(isRunning)
        .opacity(isRunning ? 0.4 : 1)
        .accessibilityLabel("Annulla e ripristina il cursore")
    }

    // MARK: - Behaviour

    private func armOrConfirm() {
        if settings.requireConfirmation {
            withAnimation(.easeIn(duration: 0.15)) { showingAlert = true }
        } else {
            onArmed()
        }
    }

    private func resetSlider() {
        guard !isRunning else { return }
        withAnimation(.spring(response: 0.42, dampingFraction: 0.76)) {
            sliderOffset = 0
        }
    }
}

// MARK: - OldOS shine label (ported from `gradientForeground` + its animation)

/// Port of OldOS' slide label: Helvetica Neue 25 with the three-stop gradient
/// mask sweeping across via animated start/end points.
private struct OldOSSlideShineLabel: View {
    let text: String

    @State private var startPoint = UnitPoint(x: -2, y: 0)
    @State private var endPoint = UnitPoint(x: 1, y: 0)

    var body: some View {
        Text(text)
            .font(.custom("Helvetica Neue", fixedSize: 25))
            .overlay(
                LinearGradient(
                    gradient: Gradient(stops: [
                        .init(color: .oldOS(78, 78, 78), location: 0.33),
                        .init(color: .white, location: 0.475),
                        .init(color: .oldOS(78, 78, 78), location: 0.525)
                    ]),
                    startPoint: startPoint,
                    endPoint: endPoint
                )
            )
            .mask(
                Text(text).font(.custom("Helvetica Neue", fixedSize: 25))
            )
            .onAppear {
                withAnimation(.easeInOut(duration: 3.6).repeatForever(autoreverses: false)) {
                    endPoint = UnitPoint(x: 2, y: 0)
                    startPoint = UnitPoint(x: 1, y: 0)
                }
            }
    }
}

// MARK: - iOS 6 glossy building blocks (drawn from the OldSafari palette)

/// iOS 6 glossy pill used for the cancel button — rounded rectangle.
private struct iOS6GlossButton: View {
    let type: OldOSButtonType
    var body: some View {
        RoundedRectangle(cornerRadius: 10)
            .fill(oldOSButtonGradient(type))
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .fill(LinearGradient(
                        colors: [Color.white.opacity(0.28), .clear],
                        startPoint: .top, endPoint: .center))
                    .padding(1)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .strokeBorder(Color.black.opacity(0.65), lineWidth: 1)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 9)
                    .strokeBorder(Color.white.opacity(0.18), lineWidth: 0.75)
                    .padding(1)
            )
            .shadow(color: .black.opacity(0.5), radius: 1, x: 0, y: 1)
    }
}

/// Same gloss, capsule shaped, used for the top "Respring" indicator.
private struct iOS6GlossCapsule: View {
    let type: OldOSButtonType
    var body: some View {
        Capsule()
            .fill(oldOSButtonGradient(type))
            .overlay(
                Capsule()
                    .fill(LinearGradient(
                        colors: [Color.white.opacity(0.26), .clear],
                        startPoint: .top, endPoint: .center))
                    .padding(1)
            )
            .overlay(Capsule().strokeBorder(Color.black.opacity(0.6), lineWidth: 1))
            .overlay(Capsule().strokeBorder(Color.white.opacity(0.16), lineWidth: 0.75).padding(1))
            .shadow(color: .black.opacity(0.45), radius: 1, x: 0, y: 1)
    }
}
