import SwiftUI

struct ContentView: View {
    @State private var progress: CGFloat = 0
    @State private var dragging = false
    @State private var active = false

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            GlassEffectContainer(spacing: 24) {
                VStack(spacing: 0) {
                    lockPill
                        .padding(.top, 10)
                    slider
                        .padding(.top, 36)
                        .padding(.horizontal, 18)
                    Spacer(minLength: 0)
                    cancel
                        .padding(.bottom, 36)
                }
            }
        }
        .preferredColorScheme(.dark)
        .fullScreenCover(isPresented: $active) {
            RespringScreen(onClose: {
                active = false
                progress = 0
            })
        }
    }

    private var lockPill: some View {
        Image(systemName: "lock.fill")
            .font(.system(size: 15, weight: .semibold))
            .foregroundStyle(.white)
            .frame(width: 108, height: 38)
            .glassEffect(.regular, in: Capsule())
            .accessibilityLabel("Bloccato")
    }

    private var slider: some View {
        GeometryReader { geo in
            let knob: CGFloat = 66
            let inset: CGFloat = 4
            let travel = max(geo.size.width - knob - inset * 2, 1)
            let x = inset + travel * progress

            ZStack(alignment: .leading) {
                Capsule()
                    .fill(.clear)
                    .frame(width: geo.size.width, height: 74)
                    .glassEffect(.regular, in: Capsule())

                Text("Scorri per spegnere")
                    .font(.system(size: 22, weight: .regular))
                    .foregroundStyle(Color.white.opacity(0.62))
                    .lineLimit(1)
                    .padding(.leading, knob + 18)
                    .opacity(max(0, 1 - Double(progress) * 1.45))

                Image(systemName: "power")
                    .font(.system(size: 30, weight: .light))
                    .foregroundStyle(.white)
                    .frame(width: knob, height: knob)
                    .glassEffect(.regular.interactive(), in: Circle())
                    .offset(x: x)
            }
            .frame(height: 74)
            .contentShape(Capsule())
            .gesture(drag(travel: travel, inset: inset))
            .animation(dragging ? nil : .spring(response: 0.42, dampingFraction: 0.82), value: progress)
            .accessibilityElement()
            .accessibilityLabel("Scorri per spegnere")
            .accessibilityValue("\(Int(progress * 100)) percento")
            .accessibilityAdjustableAction { direction in
                let next = progress + (direction == .increment ? 0.2 : -0.2)
                progress = min(1, max(0, next))
                if progress > 0.92 { finish() }
            }
        }
        .frame(height: 74)
    }

    private var cancel: some View {
        Button {
            withAnimation(.spring(response: 0.42, dampingFraction: 0.82)) {
                progress = 0
            }
        } label: {
            Image(systemName: "xmark")
                .font(.system(size: 20, weight: .semibold))
                .foregroundStyle(.white)
                .frame(width: 66, height: 66)
                .glassEffect(.regular.interactive(), in: Circle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Annulla")
    }

    private func drag(travel: CGFloat, inset: CGFloat) -> some Gesture {
        DragGesture(minimumDistance: 0)
            .onChanged { value in
                dragging = true
                let raw = (value.location.x - inset - 33) / travel
                progress = min(1, max(0, raw))
            }
            .onEnded { _ in
                dragging = false
                if progress > 0.86 {
                    progress = 1
                    finish()
                } else {
                    progress = 0
                }
            }
    }

    private func finish() {
        Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(180))
            active = true
        }
    }
}
