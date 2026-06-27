import SwiftUI
import simd

public struct Thumbstick: View {
    @Binding public var value: SIMD2<Float>
    public let radius: CGFloat
    public let label: String

    @State private var knob: CGSize = .zero

    public init(value: Binding<SIMD2<Float>>, radius: CGFloat = 60, label: String) {
        self._value = value
        self.radius = radius
        self.label = label
    }

    public var body: some View {
        ZStack {
            Circle()
                .stroke(Color.white.opacity(0.35), lineWidth: 2)
                .frame(width: radius * 2, height: radius * 2)

            Circle()
                .fill(Color.white.opacity(0.6))
                .frame(width: radius * 0.7, height: radius * 0.7)
                .offset(knob)
                .gesture(
                    DragGesture(minimumDistance: 0)
                        .onChanged { g in
                            let clamped = clamp(g.translation, to: radius)
                            knob = clamped
                            value = SIMD2<Float>(
                                Float(clamped.width / radius),
                                Float(-clamped.height / radius)    // up = +y
                            )
                        }
                        .onEnded { _ in
                            withAnimation(.spring(duration: 0.15)) { knob = .zero }
                            value = .zero
                        }
                )

            Text(label)
                .font(.caption2)
                .foregroundStyle(.white.opacity(0.6))
                .offset(y: radius + 12)
        }
        .frame(width: radius * 2, height: radius * 2)
    }

    private func clamp(_ s: CGSize, to r: CGFloat) -> CGSize {
        let d = sqrt(s.width * s.width + s.height * s.height)
        if d <= r { return s }
        let scale = r / d
        return CGSize(width: s.width * scale, height: s.height * scale)
    }
}

#Preview {
    @Previewable @State var v: SIMD2<Float> = .zero
    return Thumbstick(value: $v, label: "Move")
        .padding(40)
        .background(.black)
}
