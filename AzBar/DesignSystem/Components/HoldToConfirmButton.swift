import SwiftUI

/// A 112 pt teal medallion that must be held for `duration` seconds; a gold trim ring fills while held.
/// VoiceOver users trigger it immediately with the default activation action.
struct HoldToConfirmButton: View {
    let title: LocalizedStringKey
    var duration: Double = 1.2
    let onConfirm: () -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
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
                .stroke(Theme.Palette.track, lineWidth: 6)
            Circle()
                .trim(from: 0, to: progress)
                .stroke(Theme.Palette.gold, style: StrokeStyle(lineWidth: 6, lineCap: .round))
                .rotationEffect(.degrees(-90))
            AzMedallion(diameter: 112, fill: Theme.Palette.teal, edge: Theme.Palette.tealDeep) {
                VStack(spacing: Theme.Spacing.xs) {
                    Image(systemName: "hand.point.up.left.fill")
                        .font(.system(size: 30, weight: .semibold))
                        .accessibilityHidden(true)
                    Text(title)
                        .font(.app(.subheadline, weight: .bold))
                        .multilineTextAlignment(.center)
                        .minimumScaleFactor(0.7)
                }
                .foregroundStyle(.white)
                .padding(Theme.Spacing.m)
            }
            .environment(\.azMedallionPressed, isPressing)
        }
        .frame(width: 136, height: 136)
        .contentShape(.circle)
        .animation(reduceMotion ? nil : .smooth(duration: 0.2), value: isPressing)
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
            withAnimation(reduceMotion ? nil : .linear(duration: duration)) { progress = 1 }
        } else if !didConfirm {
            withAnimation(reduceMotion ? nil : .easeOut(duration: 0.25)) { progress = 0 }
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
        .azScreenBackground()
        .persianRoot()
}
