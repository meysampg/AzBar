// STUB (P-A): implement, keep signatures
import SwiftUI

/// `flame.fill` with a yellow → orange → red gradient, gray when not active today.
/// `.symbolEffect(.bounce, value: streak)`; breathes when active and Reduce Motion is off.
struct StreakFlame: View {
    var streak: Int
    var isActiveToday: Bool
    var size: CGFloat = 40

    var body: some View {
        Image(systemName: "flame.fill")
            .font(.system(size: size))
            .foregroundStyle(isActiveToday ? Theme.Playful.xp : Color.secondary)
    }
}
