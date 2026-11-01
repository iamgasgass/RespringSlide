import SwiftUI

/// A close SwiftUI recreation of the supplied iOS power-off screen reference.
/// Measurements are scaled from the 709 × 1536 px reference image to the
/// device's logical width. The top capsule stays below the Dynamic Island.
struct PowerOffView: View {
    @State private var sliderOffset: CGFloat = 0
    @State private var showingConfirmation = false
    @State private var engineEnabled = false
    @State private var isRunning = false
    @State private var isDragging = false

    private let referenceWidth: CGFloat = 709
    private let labelFont = Font.system(size: 22, weight: .regular, design: .default)

    var body: some View {
        GeometryReader { geometry in
            let screenWidth = geometry.size.width
            let scale = screenWidth / 393

            // Keep the established reference dimensions and positioning.
            let topCapsuleWidth = screenWidth * (324 / 1179)
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
                        .frame(width: topCapsuleWidth, height: topCapsuleHeight)
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

                if engineEnabled {
                    RespringPayloadView()
                        .ignoresSafeArea()
                        .transition(.opacity)
                        .accessibilityHidden(true)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .statusBarHidden(true)
            .confirmationDialog(
                "Avviare il respring?",
                isPresented: $showingConfirmation,
                titleVisibility: .visible
            ) {
                Button("Avvia respring", role: .destructive) {
                    startRespring()
                }
                Button("Annulla", role: .cancel) {
                    resetSlider()
                }
            } message: {
                Text("La tecnica può bloccare WebKit o riavviare SpringBoard, ma non è garantita su ogni versione di iOS. Salva prima il tuo lavoro.")
            }
        }
        .background(.black)
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
            let labelWidth = max(0, proxy.size.width - knobSize - 12)
            let sliderProgress = travel > 0 ? min(max(sliderOffset / travel, 0), 1) : 0

            ZStack(alignment: .leading) {
                // Native Liquid Glass supplies the blur, reflections, edge
                // response, and system appearance instead of a flat overlay.
                Capsule()
                    .glassEffect(.regular, in: Capsule())
                    .accessibilityHidden(true)

                Group {
                    if isRunning {
                        Text("Respring in corso")
                            .foregroundStyle(.white.opacity(0.86))
                    } else {
                        animatedPowerLabel(progress: sliderProgress, isActive: isDragging)
                    }
                }
                .font(labelFont)
                .minimumScaleFactor(0.78)
                .lineLimit(1)
                .frame(width: labelWidth, height: proxy.size.height)
                .position(
                    x: (proxy.size.width + knobSize - 12) / 2,
                    y: proxy.size.height / 2
                )
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
                            isDragging = true
                            sliderOffset = min(max(value.translation.width, 0), travel)
                        }
                        .onEnded { _ in
                            guard !isRunning else { return }
                            isDragging = false
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
                .accessibilityLabel("Scorri per avviare il respring")
                .accessibilityHint("Trascina il pulsante circolare fino all'estremità destra")
            }
        }
    }

    /// The moving specular highlight follows the thumb while the user drags,
    /// matching the illumination sweep in the iOS shutdown interaction.
    private func animatedPowerLabel(progress: CGFloat, isActive: Bool) -> some View {
        Text("Scorri per spegnere")
            .font(labelFont)
            .foregroundStyle(.white.opacity(0.38))
            .blur(radius: 0.55)
            .overlay {
                GeometryReader { geometry in
                    LinearGradient(
                        stops: [
                            .init(color: .clear, location: 0.0),
                            .init(color: .white.opacity(0.16), location: 0.30),
                            .init(color: .white.opacity(0.82), location: 0.50),
                            .init(color: .white.opacity(0.16), location: 0.70),
                            .init(color: .clear, location: 1.0)
                        ],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                    .frame(width: geometry.size.width * 0.58)
                    .offset(x: (progress - 0.29) * geometry.size.width)
                    .blur(radius: 2.2)
                    .mask {
                        Text("Scorri per spegnere")
                            .font(labelFont)
                            .lineLimit(1)
                            .minimumScaleFactor(0.78)
                    }
                    .opacity(isActive ? 1 : 0)
                    .animation(.easeOut(duration: 0.16), value: isActive)
                }
            }
            .accessibilityLabel("Scorri per spegnere")
    }

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
        isDragging = false
        withAnimation(.spring(response: 0.42, dampingFraction: 0.76)) {
            sliderOffset = 0
        }
    }

    private func startRespring() {
        isRunning = true
        withAnimation(.easeInOut(duration: 0.25)) {
            engineEnabled = true
        }
    }
}

#Preview {
    PowerOffView()
}
