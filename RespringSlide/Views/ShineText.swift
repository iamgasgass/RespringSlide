import SwiftUI

/// A single text label with a continuous specular shine sweeping left → right,
/// as on the iOS "slide to power off" label. The base text and the bright
/// (masked) text are the exact same intrinsically-sized `Text`, stacked via an
/// overlay, so they are always perfectly aligned — no ghosting.
struct ShineText: View {
    let text: String
    let font: Font
    var baseOpacity: Double = 0.34
    var bandWidth: CGFloat = 0.55
    var duration: Double = 2.1

    @State private var phase: CGFloat = -0.6

    var body: some View {
        Text(text)
            .font(font)
            .lineLimit(1)
            .fixedSize()
            .foregroundStyle(.white.opacity(baseOpacity))
            .overlay {
                Text(text)
                    .font(font)
                    .lineLimit(1)
                    .fixedSize()
                    .foregroundStyle(.white)
                    .mask {
                        GeometryReader { geo in
                            LinearGradient(
                                stops: [
                                    .init(color: .clear, location: 0.0),
                                    .init(color: .white, location: 0.5),
                                    .init(color: .clear, location: 1.0)
                                ],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                            .frame(width: geo.size.width * bandWidth)
                            .offset(x: phase * geo.size.width)
                            .frame(width: geo.size.width, height: geo.size.height, alignment: .leading)
                        }
                    }
            }
            .onAppear {
                phase = -bandWidth
                withAnimation(.linear(duration: duration).repeatForever(autoreverses: false)) {
                    phase = 1.0
                }
            }
    }
}
