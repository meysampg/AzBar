import SwiftUI

/// A circular Liquid Glass button that must be held for `duration` seconds; a ring fills while held.
/// VoiceOver users trigger it immediately with the default activation action.
struct HoldToConfirmButton: View {
    let title: LocalizedStringKey
    var duration: Double = 1.2
    let onConfirm: () -> Void

    @State private var progress: CGFloat = 0
    @State private var isPressing = false
    @State private var confirmCount = 0
    @State private var didConfirm = false

    init(_ title: LocalizedStringKey, duration: Double = 1.2, onConfirm: @escaping () -> Void) {
        self.title = title
        self.duration = duration
        self.onConfirm = onConfirm
    }

    var body: some View {
        ZStack {
            Circle()
                .stroke(.quaternary, lineWidth: 6)
            Circle()
                .trim(from: 0, to: progress)
                .stroke(.tint, style: StrokeStyle(lineWidth: 6, lineCap: .round))
                .rotationEffect(.degrees(-90))
            Text(title)
                .font(.app(.headline))
                .multilineTextAlignment(.center)
                .minimumScaleFactor(0.7)
                .padding(Theme.Spacing.m)
                .frame(width: 104, height: 104)
                .glassEffect(.regular.interactive(), in: .circle)
        }
        .frame(width: 124, height: 124)
        .contentShape(.circle)
        .scaleEffect(isPressing ? 0.96 : 1)
        .animation(.smooth(duration: 0.2), value: isPressing)
        .onLongPressGesture(minimumDuration: duration, maximumDistance: 60) {
            confirm()
        } onPressingChanged: { pressing in
            pressingChanged(pressing)
        }
        .sensoryFeedback(.impact(weight: .medium), trigger: isPressing) { _, now in now }
        .sensoryFeedback(.success, trigger: confirmCount)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text(title))
        .accessibilityAddTraits(.isButton)
        .accessibilityAction { confirm() }
    }

    private func pressingChanged(_ pressing: Bool) {
        isPressing = pressing
        if pressing {
            didConfirm = false
            var reset = Transaction()
            reset.disablesAnimations = true
            withTransaction(reset) { progress = 0 }
            withAnimation(.linear(duration: duration)) { progress = 1 }
        } else if !didConfirm {
            withAnimation(.easeOut(duration: 0.25)) { progress = 0 }
        }
    }

    private func confirm() {
        guard !didConfirm else { return }
        didConfirm = true
        confirmCount += 1
        progress = 1
        onConfirm()
    }
}

#Preview {
    HoldToConfirmButton("نیت کردم") {}
        .padding(40)
        .environment(\.layoutDirection, .rightToLeft)
}
