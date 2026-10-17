// STUB (P-A): implement, keep signatures
import SwiftUI

/// Circle in the badge tint with its symbol; locked badges are gray with a `lock.fill` overlay.
struct BadgeMedal: View {
    let badge: BadgeID
    var unlocked: Bool
    var size: CGFloat = 72

    var body: some View {
        Circle()
            .fill(unlocked ? badge.tint : Theme.Playful.locked)
            .frame(width: size, height: size)
            .overlay {
                Image(systemName: unlocked ? badge.systemImage : "lock.fill")
                    .font(.system(size: size * 0.42))
                    .foregroundStyle(.white)
            }
    }
}
