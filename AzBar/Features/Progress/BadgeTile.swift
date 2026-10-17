import SwiftUI

struct BadgeTile: View {
    let badge: BadgeID
    let unlocked: Bool
    let progress: BadgeProgress

    var body: some View {
        VStack(spacing: Theme.Spacing.s) {
            BadgeMedal(badge: badge, unlocked: unlocked, size: 64)
            Text(badge.title)
                .font(.app(.caption, weight: .semibold))
                .multilineTextAlignment(.center)
                .lineLimit(2)
            if !unlocked {
                Text("\(progress.current.fa)/\(progress.target.fa)")
                    .font(.app(.caption2))
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, Theme.Spacing.s)
        .contentShape(.rect)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(badge.title)
        .accessibilityValue(unlocked ? "به دست آمده" : "\(progress.current.fa) از \(progress.target.fa)")
        .accessibilityAddTraits(.isButton)
    }
}
