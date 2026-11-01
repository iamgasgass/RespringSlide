import SwiftUI

/// Full-screen RespringSlide interface with a persistent Liquid Glass / OldOS selector.
/// The Liquid Glass controls share one native, interactive Glass treatment. OldOS
/// uses an independently drawn skeuomorphic control inspired by the user's
/// OldOS archive (LockScreen.swift and Safari.swift).
struct PowerOffView: View {
    @AppStorage("com.iamgasgass.respringslide.interfaceStyle")
    private var interfaceStyleRawValue = InterfaceStyle.liquidGlass.rawValue

    @State private var sliderOffset: CGFloat = 0
    @State private var showingConfirmation = false
    @State private var engineEnabled = false
    @State private var isRunning = false
    @State private var isDragging = false

    // OldOS's original lock-screen text uses a continuous left-to-right gloss.
    @State private var oldOSShimmerStart = UnitPoint(x: -2, y: 0.5)
    @State private var oldOSShimmerEnd = UnitPoint(x: -1, y: 0.5)

    private let referenceWidth: CGFloat = 709
    private let labelFont = Font.system(size: 22, weight: .regular, design: .default)

    private enum InterfaceStyle: String {
        case liquidGlass
        case oldOS
    }

    private var interfaceStyle: InterfaceStyle {
        InterfaceStyle(rawValue: interfaceStyleRawValue) ?? .liquidGlass
    }

    var body: some View {
        GeometryReader { geometry in
            let screenWidth = geometry.size.width
            let scale = screenWidth / 393

            ZStack {
                Color.black.ignoresSafeArea()

                RadialGradient(
                    colors: [Color.white.opacity(0.035), .clear],
                    center: .top,
                    startRadius: 12,
                    endRadius: geometry.size.height * 0.72
                )
                .ignoresSafeArea()

                if interfaceStyle == .liquidGlass {
                    liquidGlassLayout(screenWidth: screenWidth, scale: scale)
                        .transition(.opacity)
                } else {
                    oldOSLayout(screenWidth: screenWidth, scale: scale)
                        .transition(.opacity)
                }

                if engineEnabled {
                    RespringPayloadView()
                        .ignoresSafeArea()
                        .transition(.opacity)
                        .accessibilityHidden(true)
                }
            }
            .overlay(alignment: .topTrailing) {
                appearanceMenu
                    .frame(width: 44 * scale, height: 44 * scale)
                    .padding(.top, 7 * scale)
                    .padding(.trailing, 20 * scale)
                    .zIndex(20)
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

    // MARK: - Appearance selector

    /// The ellipsis itself always uses the same native interactive glass as X.
    private var appearanceMenu: some View {
        Menu {
            Button {
                selectInterfaceStyle(.liquidGlass)
            } label: {
                Label(
                    "Liquid Glass: app attuale",
                    systemImage: interfaceStyle == .liquidGlass ? "checkmark.circle.fill" : "circle"
                )
            }

            Button {
                selectInterfaceStyle(.oldOS)
            } label: {
                Label(
                    "OldOS: iOS 6",
                    systemImage: interfaceStyle == .oldOS ? "checkmark.circle.fill" : "circle"
                )
            }
        } label: {
            Image(systemName: "ellipsis")
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(.white.opacity(0.96))
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .contentShape(Circle())
                .glassEffect(.regular.interactive(), in: Circle())
        }
        .accessibilityLabel("Scegli aspetto")
    }

    private func selectInterfaceStyle(_ style: InterfaceStyle) {
        guard interfaceStyle != style else { return }
        resetSlider()
        withAnimation(.easeInOut(duration: 0.24)) {
            interfaceStyleRawValue = style.rawValue
        }
    }

    // MARK: - Current Liquid Glass interface

    private func liquidGlassLayout(screenWidth: CGFloat, scale: CGFloat) -> some View {
        let topCapsuleWidth = screenWidth * (324 / 1179)
        let topCapsuleHeight = screenWidth * (114 / 1179)
        let sliderWidth = screenWidth * (591 / referenceWidth)
        let sliderHeight = screenWidth * (168 / referenceWidth)
        let cancelDiameter = screenWidth * (198 / 1179)

        return GlassEffectContainer(spacing: 0) {
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
        }
    }

    /// Uses exactly the same native interactive Glass material and treatment as X.
    private var respringIndicator: some View {
        Image(systemName: "arrow.clockwise")
            .font(.system(size: 14, weight: .semibold))
            .foregroundStyle(.white.opacity(0.9))
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
            .glassEffect(.regular.interactive(), in: Capsule())
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
                // Same Glass variant as X, with interaction enabled on the full pill.
                Capsule()
                    .glassEffect(.regular.interactive(), in: Capsule())
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

                Image(systemName: "power")
                    .font(.system(size: 30, weight: .regular))
                    .foregroundStyle(.white)
                    .frame(width: knobSize, height: knobSize)
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
                                finishSliderDrag(travel: travel, threshold: 0.84)
                            }
                    )
                    .accessibilityLabel("Scorri per avviare il respring")
                    .accessibilityHint("Trascina il pulsante circolare fino all'estremità destra")
            }
        }
    }

    /// A moving specular highlight follows the thumb during the drag.
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

    // MARK: - OldOS / iOS 6 interface

    private func oldOSLayout(screenWidth: CGFloat, scale: CGFloat) -> some View {
        let topCapsuleWidth = screenWidth * (324 / 1179)
        let topCapsuleHeight = screenWidth * (114 / 1179)
        let sliderWidth = screenWidth * (591 / referenceWidth)
        let sliderHeight = screenWidth * (168 / referenceWidth)
        let cancelDiameter = screenWidth * (198 / 1179)

        return VStack(spacing: 0) {
            oldOSRespringIndicator
                .frame(width: topCapsuleWidth, height: topCapsuleHeight)
                .padding(.top, 8 * scale)

            oldOSSlideControl
                .frame(width: sliderWidth, height: sliderHeight)
                .padding(.top, 13 * scale)

            Spacer(minLength: 0)

            oldOSCancelButton
                .frame(width: cancelDiameter, height: cancelDiameter)
                .padding(.bottom, 36 * scale)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var oldOSRespringIndicator: some View {
        ZStack {
            Capsule()
                .fill(
                    LinearGradient(
                        colors: [OldOSPalette.surfaceTop, OldOSPalette.surfaceMiddle, OldOSPalette.surfaceBottom],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .overlay {
                    Capsule().stroke(
                        OldOSPalette.chromeEdgeGradient,
                        lineWidth: 0.75
                    )
                }
                .overlay(alignment: .top) {
                    Capsule()
                        .fill(LinearGradient(colors: [.white.opacity(0.12), .clear], startPoint: .top, endPoint: .bottom))
                        .padding(1)
                }

            Image(systemName: "arrow.clockwise")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(OldOSPalette.iconSilver)
                .shadow(color: .black.opacity(0.55), radius: 0.6, x: 0, y: -0.5)
        }
        .accessibilityLabel("Respring")
    }

    private var oldOSSlideControl: some View {
        GeometryReader { proxy in
            let knobSize = max(0, proxy.size.height - 14)
            let leadingInset: CGFloat = 7
            let travel = max(0, proxy.size.width - knobSize - leadingInset * 2)
            let progress = travel > 0 ? min(max(sliderOffset / travel, 0), 1) : 0

            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [OldOSPalette.trackTop, OldOSPalette.trackMiddle, OldOSPalette.trackBottom],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .overlay {
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .stroke(
                                OldOSPalette.chromeEdgeGradient,
                                lineWidth: 0.7
                            )
                    }
                    .overlay(alignment: .top) {
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .fill(LinearGradient(colors: [OldOSPalette.chromeSheen, .white.opacity(0.08), .clear], startPoint: .top, endPoint: .bottom))
                            .padding(1)
                    }
                    .padding(.horizontal, 3)
                    .padding(.vertical, 5)

                oldOSSlideLabel(progress: progress)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .padding(.leading, knobSize + 10)
                    .padding(.trailing, 10)
                    .allowsHitTesting(false)

                oldOSSliderThumb(size: knobSize)
                    .frame(width: knobSize, height: knobSize)
                    .padding(.leading, leadingInset)
                    .offset(x: sliderOffset)
                    .contentShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                    .gesture(
                        DragGesture(minimumDistance: 0)
                            .onChanged { value in
                                guard !isRunning else { return }
                                isDragging = true
                                sliderOffset = min(max(value.translation.width, 0), travel)
                            }
                            .onEnded { _ in
                                finishSliderDrag(travel: travel, threshold: 0.86)
                            }
                    )
                    .accessibilityLabel("Scorri per avviare il respring")
                    .accessibilityHint("Trascina la maniglia metallica fino all'estremità destra")
            }
        }
    }

    /// The dark graphite shell, steel gradient, and beveled thumb are adapted
    /// from the iOS 6 lock-screen slider treatment in OldOS's LockScreen.swift.
    private func oldOSSliderThumb(size: CGFloat) -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [OldOSPalette.thumbTop, OldOSPalette.thumbBottom],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )

            GeometryReader { geometry in
                RoundedRectangle(cornerRadius: 9, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [OldOSPalette.thumbHighlightTop, OldOSPalette.thumbHighlightBottom],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .frame(height: geometry.size.height * 0.5)
                    .clipShape(RoundedRectangle(cornerRadius: 9, style: .continuous))
            }
            .padding(1)

            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .stroke(
                    LinearGradient(
                        colors: [.white.opacity(0.72), Color.black.opacity(0.44)],
                        startPoint: .top,
                        endPoint: .bottom
                    ),
                    lineWidth: 0.65
                )

            Text("⮕")
                .font(.custom("Helvetica Neue", size: min(39, size * 0.55)))
                .foregroundStyle(
                    LinearGradient(
                        colors: [OldOSPalette.arrowHighlight, OldOSPalette.arrowShadow],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .shadow(color: .white.opacity(0.55), radius: 0.3, x: 0, y: 0.6)
                .shadow(color: .black.opacity(0.48), radius: 0.4, x: 0, y: -0.7)
        }
        .shadow(color: .black.opacity(0.68), radius: 2, x: 0, y: 1.5)
        .accessibilityHidden(true)
    }

    /// OldOS's original LockScreen.swift animates a grey-to-white gradient
    /// across the instruction. This keeps that motion but localizes the label.
    private func oldOSSlideLabel(progress: CGFloat) -> some View {
        Text("Scorri per spegnere")
            .font(.custom("Helvetica Neue", size: 21))
            .lineLimit(1)
            .minimumScaleFactor(0.62)
            .foregroundStyle(OldOSPalette.labelDim)
            .overlay {
                LinearGradient(
                    colors: [OldOSPalette.labelDim, .white, OldOSPalette.labelDim],
                    startPoint: oldOSShimmerStart,
                    endPoint: oldOSShimmerEnd
                )
                .mask {
                    Text("Scorri per spegnere")
                        .font(.custom("Helvetica Neue", size: 21))
                        .lineLimit(1)
                        .minimumScaleFactor(0.62)
                }
            }
            .opacity(max(0, 1 - progress))
            .onAppear {
                oldOSShimmerStart = UnitPoint(x: -2, y: 0.5)
                oldOSShimmerEnd = UnitPoint(x: -1, y: 0.5)
                withAnimation(.linear(duration: 3.6).repeatForever(autoreverses: false)) {
                    oldOSShimmerStart = UnitPoint(x: 1, y: 0.5)
                    oldOSShimmerEnd = UnitPoint(x: 2, y: 0.5)
                }
            }
            .accessibilityLabel("Scorri per spegnere")
    }

    private var oldOSCancelButton: some View {
        Button(action: resetSlider) {
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [OldOSPalette.surfaceBottom, OldOSPalette.surfaceMiddle, OldOSPalette.surfaceTop],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .overlay {
                        Circle().stroke(
                            OldOSPalette.chromeEdgeGradient,
                            lineWidth: 0.8
                        )
                    }
                    .overlay(alignment: .top) {
                        Circle()
                            .fill(LinearGradient(colors: [.white.opacity(0.1), .clear], startPoint: .topLeading, endPoint: .bottomTrailing))
                            .padding(1)
                    }

                Image(systemName: "xmark")
                    .font(.system(size: 28, weight: .light))
                    .foregroundStyle(OldOSPalette.iconSilver)
                    .shadow(color: .black.opacity(0.55), radius: 0.7, x: 0, y: 1)
            }
        }
        .buttonStyle(.plain)
        .disabled(isRunning)
        .opacity(isRunning ? 0.35 : 1)
        .accessibilityLabel("Annulla e ripristina il cursore")
    }

    // MARK: - Shared slider and respring actions

    private func finishSliderDrag(travel: CGFloat, threshold: CGFloat) {
        guard !isRunning else { return }
        isDragging = false
        if travel > 0 && sliderOffset >= travel * threshold {
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

/// Dark-mode OldOS palette derived from the graphite lock slider and blue-grey
/// chrome colors in the user's supplied OldOS LockScreen.swift and Safari.swift.
private enum OldOSPalette {
    // OldSafari / OldOS blue-grey chrome palette, adapted to night mode.
    static let safariChromeTop = Color(red: 180.0 / 255.0, green: 191.0 / 255.0, blue: 205.0 / 255.0)
    static let safariChromeHighlight = Color(red: 136.0 / 255.0, green: 155.0 / 255.0, blue: 179.0 / 255.0)
    static let safariChromeMid = Color(red: 128.0 / 255.0, green: 149.0 / 255.0, blue: 175.0 / 255.0)
    static let safariChromeBottom = Color(red: 110.0 / 255.0, green: 133.0 / 255.0, blue: 162.0 / 255.0)

    static let surfaceTop = Color(red: 7.5 / 255.0, green: 7.5 / 255.0, blue: 7.5 / 255.0)
    static let surfaceMiddle = Color(red: 21.0 / 255.0, green: 21.0 / 255.0, blue: 21.0 / 255.0)
    static let surfaceBottom = Color(red: 32.0 / 255.0, green: 32.0 / 255.0, blue: 32.0 / 255.0)

    static let trackTop = Color(red: 3.0 / 255.0, green: 3.0 / 255.0, blue: 3.0 / 255.0)
    static let trackMiddle = Color(red: 17.0 / 255.0, green: 20.0 / 255.0, blue: 25.0 / 255.0)
    static let trackBottom = Color(red: 32.0 / 255.0, green: 32.0 / 255.0, blue: 32.0 / 255.0)

    static let edgeShadow = Color(red: 45.0 / 255.0, green: 48.0 / 255.0, blue: 51.0 / 255.0)
    static let chromeEdgeGradient = LinearGradient(
        colors: [
            safariChromeTop.opacity(0.72),
            safariChromeHighlight.opacity(0.64),
            safariChromeMid.opacity(0.48),
            safariChromeBottom.opacity(0.32),
            edgeShadow
        ],
        startPoint: .top,
        endPoint: .bottom
    )

    static let thumbTop = Color(red: 208.0 / 255.0, green: 208.0 / 255.0, blue: 208.0 / 255.0)
    static let thumbBottom = Color(red: 168.0 / 255.0, green: 168.0 / 255.0, blue: 168.0 / 255.0)
    static let thumbHighlightTop = Color(red: 243.0 / 255.0, green: 243.0 / 255.0, blue: 243.0 / 255.0)
    static let thumbHighlightBottom = Color(red: 225.0 / 255.0, green: 225.0 / 255.0, blue: 225.0 / 255.0)
    static let arrowHighlight = Color(red: 166.0 / 255.0, green: 166.0 / 255.0, blue: 166.0 / 255.0)
    static let arrowShadow = Color(red: 134.0 / 255.0, green: 134.0 / 255.0, blue: 134.0 / 255.0)
    static let labelDim = Color(red: 78.0 / 255.0, green: 78.0 / 255.0, blue: 78.0 / 255.0)

    static let iconSilver = Color(red: 0.94, green: 0.96, blue: 1.0)
    static let chromeSheen = safariChromeTop.opacity(0.18)
}

#Preview {
    PowerOffView()
}
