import SwiftUI

/// `flame.fill` with a yellow → orange → red gradient, gray when not active today.
/// `.symbolEffect(.bounce, value: streak)`; breathes when active and Reduce Motion is off.
struct StreakFlame: View {
    var streak: Int
    var isActiveToday: Bool
    var size: CGFloat = 40

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        Image(systemName: "flame.fill")
            .font(.system(size: size))
            .foregroundStyle(
                isActiveToday
                    ? AnyShapeStyle(LinearGradient(colors: [.yellow, .orange, .red], startPoint: .top, endPoint: .bottom))
                    : AnyShapeStyle(Color(.systemGray3))
            )
            .shadow(color: isActiveToday ? .orange.opacity(0.35) : .clear, radius: size * 0.15, y: size * 0.05)
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
    .persianRoot()
}
