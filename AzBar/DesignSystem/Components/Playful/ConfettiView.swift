import SwiftUI

/// TimelineView + Canvas particles bursting each time `trigger` changes (and once on appear);
/// hit-testing off. Reduce Motion renders nothing. The burst is symmetric, so it needs no RTL care.
struct ConfettiView: View {
    var trigger: Int
    var count: Int = 80
    var duration: Double = 2.5

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var start: Date?

    private struct Particle {
        var angle: Double
        var speed: Double
        var size: CGFloat
        var spin: Double
        var colorIndex: Int
        var round: Bool
        var delay: Double
    }

    private static let colors: [Color] = [.red, .orange, .yellow, .green, .teal, .blue, .purple, .pink]

    private func particles() -> [Particle] {
        var rng = SplitMix(seed: UInt64(truncatingIfNeeded: trigger) &* 0x9E37_79B9 &+ 17)
        return (0..<max(count, 0)).map { _ in
            Particle(
                angle: -Double.pi / 2 + (rng.unit() - 0.5) * Double.pi * 1.5,
                speed: 260 + rng.unit() * 520,
                size: 6 + rng.unit() * 7,
                spin: (rng.unit() - 0.5) * 14,
                colorIndex: Int(rng.unit() * Double(Self.colors.count)) % Self.colors.count,
                round: rng.unit() < 0.35,
                delay: rng.unit() * 0.12
            )
        }
    }

    var body: some View {
        if reduceMotion {
            EmptyView()
        } else {
            TimelineView(.animation(paused: start == nil)) { context in
                Canvas { gc, size in
                    guard let start else { return }
                    let elapsed = context.date.timeIntervalSince(start)
                    guard elapsed >= 0, elapsed < duration else { return }
                    let origin = CGPoint(x: size.width / 2, y: size.height * 0.4)
                    for p in particles() {
                        let t = elapsed - p.delay
                        guard t > 0 else { continue }
                        let drag = exp(-t * 1.6)
                        let x = origin.x + cos(p.angle) * p.speed * (1 - drag) / 1.6
                        let y = origin.y + sin(p.angle) * p.speed * (1 - drag) / 1.6 + 420 * t * t
                        let fade = min(1, max(0, (duration - elapsed) / (duration * 0.35)))
                        var layer = gc
                        layer.opacity = fade
                        layer.translateBy(x: x, y: y)
                        layer.rotate(by: .radians(p.spin * t))
                        let rect = CGRect(x: -p.size / 2, y: -p.size / 3, width: p.size, height: p.size * 0.66)
                        let shape = p.round ? Path(ellipseIn: rect) : Path(roundedRect: rect, cornerRadius: 1.5)
                        layer.fill(shape, with: .color(Self.colors[p.colorIndex]))
                    }
                }
            }
            .allowsHitTesting(false)
            .accessibilityHidden(true)
            .onAppear { restart() }
            .onChange(of: trigger) { _, _ in restart() }
        }
    }

    private func restart() { start = .now }
}

private struct SplitMix {
    var state: UInt64
    init(seed: UInt64) { state = seed }
    mutating func next() -> UInt64 {
        state &+= 0x9E37_79B9_7F4A_7C15
        var z = state
        z = (z ^ (z >> 30)) &* 0xBF58_476D_1CE4_E5B9
        z = (z ^ (z >> 27)) &* 0x94D0_49BB_1331_11EB
        return z ^ (z >> 31)
    }
    mutating func unit() -> Double { Double(next() >> 11) / Double(1 << 53) }
}

#Preview {
    ConfettiView(trigger: 1)
        .persianRoot()
}
