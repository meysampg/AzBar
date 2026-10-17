import SwiftUI

/// Solid `flame.fill` (flame colour when active today, sand otherwise).
/// `.symbolEffect(.bounce, value: streak)`; breathes when active and Reduce Motion is off.
struct StreakFlame: View {
    var streak: Int
    var isActiveToday: Bool
    var size: CGFloat = 40

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        Image(systemName: "flame.fill")
            .font(.system(size: size))
            .foregroundStyle(isActiveToday ? Theme.Palette.flame : Theme.Palette.sand)
            .symbolEffect(.bounce, value: streak)
            .symbolEffect(.breathe, isActive: isActiveToday && !reduceMotion)
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("زنجیرهٔ تمرین")
            .accessibilityValue(isActiveToday ? "\(streak.fa) روز پیاپی، امروز روشن است" : "\(streak.fa) روز پیاپی، امروز هنوز تمرین نکرده‌اید")
    }
}

#Preview {
    HStack(spacing: 24) {
        StreakFlame(streak: 5, isActiveToday: true, size: 56)
        StreakFlame(streak: 5, isActiveToday: false, size: 56)
    }
    .padding()
    .azScreenBackground()
    .persianRoot()
}
