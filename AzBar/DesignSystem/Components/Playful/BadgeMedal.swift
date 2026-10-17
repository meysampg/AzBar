import SwiftUI

/// Medallion in the badge tint with its symbol and a light rim; locked badges are sand with a lock chip.
struct BadgeMedal: View {
    let badge: BadgeID
    var unlocked: Bool
    var size: CGFloat = 72

    var body: some View {
        let tint = badge.tint
        AzMedallion(
            diameter: size,
            fill: unlocked ? tint : Theme.Palette.lockedFill,
            rim: unlocked ? tint.mix(with: .white, by: 0.25) : Theme.Palette.sand,
            rimWidth: max(2, size * 0.04),
            edge: unlocked ? tint.mix(with: .black, by: 0.2) : Theme.Palette.sand,
            edgeDepth: max(2, size * 0.05)
        ) {
            Image(systemName: badge.systemImage)
                .font(.system(size: size * 0.42, weight: .bold))
                .foregroundStyle(unlocked ? badge.symbolColor : Theme.Palette.lockedSymbol)
        }
        .overlay(alignment: .bottomTrailing) {
            if !unlocked {
                Image(systemName: "lock.fill")
                    .font(.system(size: size * 0.18, weight: .bold))
                    .foregroundStyle(.white)
                    .padding(size * 0.09)
                    .background(Theme.Palette.sandDeep, in: Circle())
            }
        }
        .padding(.bottom, max(2, size * 0.05))
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(badge.title)
        .accessibilityValue(unlocked ? "به‌دست آمده" : "قفل")
    }
}

#Preview {
    HStack {
        BadgeMedal(badge: .streak7, unlocked: true)
        BadgeMedal(badge: .firstChallenge, unlocked: true)
        BadgeMedal(badge: .firstGhazal, unlocked: false)
    }
    .padding()
    .azScreenBackground()
    .persianRoot()
}
