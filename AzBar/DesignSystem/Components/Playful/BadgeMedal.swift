import SwiftUI

/// Circle in the badge tint with its symbol and a darker rim; locked badges are gray with a `lock.fill` overlay.
struct BadgeMedal: View {
    let badge: BadgeID
    var unlocked: Bool
    var size: CGFloat = 72

    var body: some View {
        let base = unlocked ? badge.tint : Theme.Playful.locked
        Circle()
            .fill(LinearGradient(colors: [base.mix(with: .white, by: 0.2), base], startPoint: .top, endPoint: .bottom))
            .frame(width: size, height: size)
            .overlay {
                Circle().strokeBorder(base.mix(with: .black, by: 0.25), lineWidth: max(2, size * 0.06))
            }
            .overlay {
                Image(systemName: badge.systemImage)
                    .font(.system(size: size * 0.42, weight: .bold))
                    .foregroundStyle(unlocked ? Color.white : Color.secondary.opacity(0.7))
            }
            .overlay(alignment: .bottomTrailing) {
                if !unlocked {
                    Image(systemName: "lock.fill")
                        .font(.system(size: size * 0.2, weight: .bold))
                        .foregroundStyle(.white)
                        .padding(size * 0.1)
                        .background(Color(.systemGray), in: Circle())
                }
            }
            .shadow(color: unlocked ? base.opacity(0.35) : .clear, radius: size * 0.1, y: size * 0.04)
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(badge.title)
            .accessibilityValue(unlocked ? "به‌دست آمده" : "قفل")
    }
}

#Preview {
    HStack {
        BadgeMedal(badge: .streak7, unlocked: true)
        BadgeMedal(badge: .firstGhazal, unlocked: false)
    }
    .padding()
    .persianRoot()
}
