import SwiftUI
import UIKit

/// The "OldOS" skin: a maniacally faithful recreation of the iOS 6
/// "slide to power off" screen, drawn with the OldSafari / OldOS appearance
/// kit (`OldOSKit` + `OldSafariPalette`) so the palette, glossy sheet-metal
/// controls and 2012 typography match the OldSafari project exactly. It is laid
/// out to run full screen on modern iOS/iPadOS devices while keeping the iOS 6
/// look. Behaviour (slide → confirm → respring) is identical to the Liquid
/// Glass skin; engine state is owned by the parent.
struct OldOSPowerOffView: View {
    let isRunning: Bool
    let onArmed: () -> Void

    @StateObject private var safeArea = OldOSSafeArea()

    @State private var sliderOffset: CGFloat = 0
    @State private var isDragging = false
    @State private var showingConfirmation = false
    @State private var shimmerPhase: CGFloat = -1

    var body: some View {
        GeometryReader { geometry in
            let w = geometry.size.width
            let trackWidth = min(w - 44, 560)
            let trackHeight: CGFloat = 74
            let topInset = max(safeArea.insets.top, 20)
            let bottomInset = max(safeArea.insets.bottom, 16)

            ZStack {
                // iOS 6 power-off backdrop: near-black with a faint top vignette.
                Color.black.ignoresSafeArea()
                RadialGradient(
                    colors: [Color.oldOS(42, 44, 48).opacity(0.55), .clear],
                    center: .top, startRadius: 8, endRadius: geometry.size.height * 0.8
                )
                .ignoresSafeArea()

                VStack(spacing: 0) {
                    respringIndicator
                        .padding(.top, topInset + 8)

                    slideToPowerOff(width: trackWidth, height: trackHeight)
                        .padding(.top, 26)

                    Spacer(minLength: 0)

                    cancelButton(width: trackWidth)
                        .padding(.bottom, bottomInset + 20)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .confirmationDialog(
                "Avviare il respring?",
                isPresented: $showingConfirmation,
                titleVisibility: .visible
            ) {
                Button("Avvia respring", role: .destructive) { onArmed() }
                Button("Annulla", role: .cancel) { resetSlider() }
            } message: {
                Text("La tecnica può bloccare WebKit o riavviare SpringBoard, ma non è garantita su ogni versione di iOS. Salva prima il tuo lavoro.")
            }
            .onAppear(perform: startShimmer)
        }
        .preferredColorScheme(.dark)
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

    // MARK: - Slide to power off

    private func slideToPowerOff(width: CGFloat, height: CGFloat) -> some View {
        let knobInset: CGFloat = 4
        let knobSize = height - knobInset * 2
        let travel = max(0, width - knobSize - knobInset * 2)

        return ZStack(alignment: .leading) {
            // Recessed glossy translucent track (iOS 6 "slot").
            OldOSInnerShadow(
                shape: Capsule(),
                fill: LinearGradient(oldOS: [
                    OldOSStop(.oldOS(20, 20, 22, 0.92), 0),
                    OldOSStop(.oldOS(8, 8, 10, 0.92), 0.5),
                    OldOSStop(.oldOS(4, 4, 6, 0.94), 0.5),
                    OldOSStop(.oldOS(14, 14, 16, 0.94), 1)
                ]),
                radius: 2.2,
                offset: CGPoint(x: 0, y: 1.5),
                intensity: 0.85
            )
            .overlay(
                Capsule()
                    .stroke(Color.white.opacity(0.14), lineWidth: 0.75)
                    .padding(0.5)
            )
            .overlay(
                // Thin top sheen.
                Capsule()
                    .fill(LinearGradient(
                        colors: [Color.white.opacity(0.10), .clear],
                        startPoint: .top, endPoint: .center))
                    .padding(1.5)
                    .allowsHitTesting(false)
            )

            // Single "scorri per spegnere" label, centred in the track, with a
            // continuous iOS 6 shine sweep.
            shimmerLabel
                .frame(width: width, height: height)
                .allowsHitTesting(false)

            // White glossy knob with the red power glyph.
            iOS6PowerKnob()
                .frame(width: knobSize, height: knobSize)
                .padding(knobInset)
                .offset(x: sliderOffset)
                .gesture(
                    DragGesture(minimumDistance: 0)
                        .onChanged { value in
                            guard !isRunning else { return }
                            isDragging = true
                            sliderOffset = min(max(value.translation.width, 0), travel)
                        }
                        .onEnded { _ in
                            guard !isRunning else { return }
                            isDragging = false
                            if travel > 0 && sliderOffset >= travel * 0.84 {
                                UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                                withAnimation(.spring(response: 0.28, dampingFraction: 0.88)) {
                                    sliderOffset = travel
                                }
                                showingConfirmation = true
                            } else {
                                withAnimation(.spring(response: 0.42, dampingFraction: 0.76)) {
                                    sliderOffset = 0
                                }
                            }
                        }
                )
                .accessibilityLabel("Scorri per spegnere")
                .accessibilityHint("Trascina fino all'estremità destra per avviare il respring")
        }
        .frame(width: width, height: height)
    }

    private var shimmerLabel: some View {
        let text = isRunning ? "Respring in corso" : "scorri per spegnere"
        return Text(text)
            .font(OldOSFont.bold(23))
            .foregroundColor(.white.opacity(0.30))
            .shadow(color: .black.opacity(0.6), radius: 0, x: 0, y: -1)
            .lineLimit(1)
            .minimumScaleFactor(0.7)
            .overlay(
                GeometryReader { geo in
                    LinearGradient(
                        stops: [
                            .init(color: .clear, location: 0.0),
                            .init(color: .white.opacity(0.95), location: 0.5),
                            .init(color: .clear, location: 1.0)
                        ],
                        startPoint: .leading, endPoint: .trailing
                    )
                    .frame(width: geo.size.width * 0.5)
                    .offset(x: shimmerPhase * geo.size.width)
                    .mask(
                        Text(text)
                            .font(OldOSFont.bold(23))
                            .lineLimit(1)
                            .minimumScaleFactor(0.7)
                            .frame(width: geo.size.width, height: geo.size.height)
                    )
                    .opacity(isRunning ? 0 : 1)
                }
            )
    }

    // MARK: - Cancel

    private func cancelButton(width: CGFloat) -> some View {
        Button {
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
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

    private func resetSlider() {
        guard !isRunning else { return }
        isDragging = false
        withAnimation(.spring(response: 0.42, dampingFraction: 0.76)) {
            sliderOffset = 0
        }
    }

    private func startShimmer() {
        shimmerPhase = -0.6
        withAnimation(.linear(duration: 2.1).repeatForever(autoreverses: false)) {
            shimmerPhase = 1.1
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

/// The white glossy knob carrying the red power glyph, as on the iOS 6 slider.
private struct iOS6PowerKnob: View {
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 9)
                .fill(LinearGradient(oldOS: [
                    OldOSStop(.oldOS(255, 255, 255), 0),
                    OldOSStop(.oldOS(244, 245, 247), 0.5),
                    OldOSStop(.oldOS(226, 228, 232), 0.5),
                    OldOSStop(.oldOS(236, 238, 242), 1)
                ]))
                .overlay(
                    RoundedRectangle(cornerRadius: 9)
                        .fill(LinearGradient(
                            colors: [Color.white.opacity(0.9), .clear],
                            startPoint: .top, endPoint: .center))
                        .padding(1)
                )
                .overlay(RoundedRectangle(cornerRadius: 9)
                    .strokeBorder(Color.oldOS(120, 122, 128), lineWidth: 0.75))
                .shadow(color: .black.opacity(0.55), radius: 1.5, x: 0, y: 1)

            Image(systemName: "power")
                .font(.system(size: 26, weight: .semibold))
                .foregroundStyle(LinearGradient(oldOS: [
                    OldOSStop(.oldOS(214, 58, 48), 0),
                    OldOSStop(.oldOS(168, 26, 22), 1)
                ]))
                .shadow(color: .white.opacity(0.7), radius: 0, x: 0, y: 0.75)
        }
    }
}
