import SwiftUI

/// The "Liquid Glass" skin: the iOS 27-style slide-to-power-off control drawn
/// entirely with the native SwiftUI `glassEffect(.regular…)` material — the
/// identical material used by the X button — so the track, the bubble and the
/// thumb are literally Liquid Glass.
///
/// There is a single "scorri per spegnere" label centred in the track with a
/// continuous shine. The top bubble shows the same "⟳ Respring" content as the
/// OldOS skin, and the glass X cancel button is shown at the bottom. Engine
/// state is owned by the parent so both skins share it.
struct LiquidGlassPowerOffView: View {
    let isRunning: Bool
    let onArmed: () -> Void

    @State private var sliderOffset: CGFloat = 0
    @State private var showingConfirmation = false

    private let referenceWidth: CGFloat = 709
    private let labelFont = Font.system(size: 22, weight: .regular, design: .default)

    var body: some View {
        GeometryReader { geometry in
            let screenWidth = geometry.size.width
            let scale = screenWidth / 393

            let topCapsuleHeight = screenWidth * (114 / 1179)
            let sliderWidth = screenWidth * (591 / referenceWidth)
            let sliderHeight = screenWidth * (168 / referenceWidth)
            let cancelDiameter = screenWidth * (198 / 1179)

            ZStack {
                Color.black.ignoresSafeArea()

                RadialGradient(
                    colors: [Color.white.opacity(0.035), .clear],
                    center: .top,
                    startRadius: 12,
                    endRadius: geometry.size.height * 0.72
                )
                .ignoresSafeArea()

                VStack(spacing: 0) {
                    respringIndicator
                        .frame(height: topCapsuleHeight)
                        .padding(.top, 8 * scale)

                    slideControl
                        .frame(width: sliderWidth, height: sliderHeight)
                        .padding(.top, 13 * scale)

                    Spacer(minLength: 0)

                    cancelButton
                        .frame(width: cancelDiameter, height: cancelDiameter)
                        .padding(.bottom, 36 * scale)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .confirmationDialog(
                "Avviare il respring?",
                isPresented: $showingConfirmation,
                titleVisibility: .visible
            ) {
                Button("Avvia respring", role: .destructive) {
                    onArmed()
                }
                Button("Annulla", role: .cancel) {
                    resetSlider()
                }
            } message: {
                Text("La tecnica può bloccare WebKit o riavviare SpringBoard, ma non è garantita su ogni versione di iOS. Salva prima il tuo lavoro.")
            }
        }
        .preferredColorScheme(.dark)
    }

    /// The top bubble, same "⟳ Respring" content as the OldOS skin, rendered in
    /// the native Liquid Glass material.
    private var respringIndicator: some View {
        HStack(spacing: 7) {
            Image(systemName: "arrow.clockwise")
                .font(.system(size: 14, weight: .semibold))
            Text("Respring")
                .font(.system(size: 16, weight: .semibold))
        }
        .foregroundStyle(.white.opacity(0.92))
        .padding(.horizontal, 20)
        .padding(.vertical, 9)
        .glassEffect(.regular, in: Capsule())
        .accessibilityLabel("Respring")
    }

    private var slideControl: some View {
        GeometryReader { proxy in
            let knobInset = proxy.size.height * (24 / 168)
            let knobSize = proxy.size.height - knobInset
            let travel = max(0, proxy.size.width - knobSize - knobInset)

            ZStack(alignment: .leading) {
                Capsule()
                    .glassEffect(.regular, in: Capsule())
                    .accessibilityHidden(true)

                // Single centred label with a continuous shine.
                Group {
                    if isRunning {
                        Text("Respring in corso")
                            .font(labelFont)
                            .foregroundStyle(.white.opacity(0.86))
                            .lineLimit(1)
                    } else {
                        ShineText(text: "Scorri per spegnere", font: labelFont, baseOpacity: 0.38)
                    }
                }
                .frame(width: proxy.size.width, height: proxy.size.height)
                .allowsHitTesting(false)

                ZStack {
                    Image(systemName: "power")
                        .font(.system(size: 30, weight: .regular))
                        .foregroundStyle(.white)
                }
                .frame(width: knobSize, height: knobSize)
                .glassEffect(.regular.interactive(), in: Circle())
                .padding(knobInset / 2)
                .offset(x: sliderOffset)
                .gesture(
                    DragGesture(minimumDistance: 0)
                        .onChanged { value in
                            guard !isRunning else { return }
                            sliderOffset = min(max(value.translation.width, 0), travel)
                        }
                        .onEnded { _ in
                            guard !isRunning else { return }
                            if travel > 0 && sliderOffset >= travel * 0.84 {
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
                .accessibilityHint("Trascina il pulsante circolare fino all'estremità destra")
            }
        }
    }

    /// The glass X cancel button, identical Liquid Glass material as the thumb.
    private var cancelButton: some View {
        Button(action: resetSlider) {
            Image(systemName: "xmark")
                .font(.system(size: 28, weight: .light))
                .foregroundStyle(.white.opacity(0.96))
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .glassEffect(.regular.interactive(), in: Circle())
        }
        .buttonStyle(.plain)
        .disabled(isRunning)
        .opacity(isRunning ? 0.35 : 1)
        .accessibilityLabel("Annulla e ripristina il cursore")
    }

    private func resetSlider() {
        guard !isRunning else { return }
        withAnimation(.spring(response: 0.42, dampingFraction: 0.76)) {
            sliderOffset = 0
        }
    }
}
