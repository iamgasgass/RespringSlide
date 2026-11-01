import SwiftUI

/// The "Liquid Glass" skin: the iOS 27-style slide-to-power-off control drawn
/// entirely with the native SwiftUI `glassEffect(.regular…)` material — the
/// identical material used by the X button — so the track, the bubble and the
/// thumb are literally Liquid Glass.
///
/// There is a single label, "scorri per spegnere", centred in the track with a
/// continuous specular shine. No cancel X is shown in this mode. Engine state
/// is owned by the parent so both skins share it.
struct LiquidGlassPowerOffView: View {
    /// Driven by the parent, true while the respring engine runs.
    let isRunning: Bool
    /// Called when the user completes the slider and confirms.
    let onArmed: () -> Void

    @State private var sliderOffset: CGFloat = 0
    @State private var showingConfirmation = false
    @State private var shimmerPhase: CGFloat = -0.6

    private let referenceWidth: CGFloat = 709
    private let labelFont = Font.system(size: 22, weight: .regular, design: .default)

    var body: some View {
        GeometryReader { geometry in
            let screenWidth = geometry.size.width
            let scale = screenWidth / 393

            let topCapsuleWidth = screenWidth * (324 / 1179)
            let topCapsuleHeight = screenWidth * (114 / 1179)
            let sliderWidth = screenWidth * (591 / referenceWidth)
            let sliderHeight = screenWidth * (168 / referenceWidth)

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
                        .frame(width: topCapsuleWidth, height: topCapsuleHeight)
                        .padding(.top, 8 * scale)

                    slideControl
                        .frame(width: sliderWidth, height: sliderHeight)
                        .padding(.top, 13 * scale)

                    Spacer(minLength: 0)
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
            .onAppear(perform: startShimmer)
        }
        .preferredColorScheme(.dark)
    }

    /// Uses the platform Liquid Glass material without a hand-painted fill,
    /// outline, or shadow, allowing iOS to render its current system variant.
    private var respringIndicator: some View {
        Image(systemName: "arrow.clockwise")
            .font(.system(size: 14, weight: .semibold))
            .foregroundStyle(.white.opacity(0.9))
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
            .glassEffect(.regular, in: Capsule())
            .accessibilityLabel("Respring")
    }

    private var slideControl: some View {
        GeometryReader { proxy in
            let knobInset = proxy.size.height * (24 / 168)
            let knobSize = proxy.size.height - knobInset
            let travel = max(0, proxy.size.width - knobSize - knobInset)

            ZStack(alignment: .leading) {
                // Native Liquid Glass supplies the blur, reflections, edge
                // response, and system appearance instead of a flat overlay.
                Capsule()
                    .glassEffect(.regular, in: Capsule())
                    .accessibilityHidden(true)

                // Single centred label with a continuous shine.
                shimmerLabel
                    .frame(width: proxy.size.width, height: proxy.size.height)
                    .allowsHitTesting(false)

                ZStack {
                    Image(systemName: "power")
                        .font(.system(size: 30, weight: .regular))
                        .foregroundStyle(.white)
                }
                .frame(width: knobSize, height: knobSize)
                // The interactive system variant creates the responsive,
                // non-uniform specular response as the user touches and drags.
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

    /// The single "scorri per spegnere" label, centred in the track, with a
    /// specular highlight that continuously sweeps left → right.
    private var shimmerLabel: some View {
        let text = isRunning ? "Respring in corso" : "Scorri per spegnere"
        return Text(text)
            .font(labelFont)
            .foregroundStyle(.white.opacity(0.38))
            .lineLimit(1)
            .minimumScaleFactor(0.78)
            .frame(maxWidth: .infinity)
            .multilineTextAlignment(.center)
            .overlay {
                GeometryReader { geometry in
                    LinearGradient(
                        stops: [
                            .init(color: .clear, location: 0.0),
                            .init(color: .white.opacity(0.16), location: 0.30),
                            .init(color: .white.opacity(0.95), location: 0.50),
                            .init(color: .white.opacity(0.16), location: 0.70),
                            .init(color: .clear, location: 1.0)
                        ],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                    .frame(width: geometry.size.width * 0.5)
                    .offset(x: shimmerPhase * geometry.size.width)
                    .blur(radius: 1.2)
                    .mask {
                        Text(text)
                            .font(labelFont)
                            .lineLimit(1)
                            .minimumScaleFactor(0.78)
                            .frame(width: geometry.size.width, height: geometry.size.height)
                            .multilineTextAlignment(.center)
                    }
                    .opacity(isRunning ? 0 : 1)
                }
            }
            .accessibilityLabel(text)
    }

    private func resetSlider() {
        guard !isRunning else { return }
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
