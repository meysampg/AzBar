import SwiftUI

/// Streak flame, daily XP goal ring, level and freezes, plus the due line and review CTA.
/// Rendered as the content of one List row.
struct TodayHeroCard: View {
    let streak: Int
    let isActiveToday: Bool
    let todayXP: Int
    let dailyGoal: Int
    let level: Int
    let freezes: Int
    let dueCount: Int
    let onStartReview: () -> Void

    var body: some View {
        VStack(spacing: Theme.Spacing.l) {
            HStack(spacing: Theme.Spacing.m) {
                StreakFlame(streak: streak, isActiveToday: isActiveToday, size: 44)
                    .accessibilityHidden(true)
                VStack(alignment: .leading, spacing: 2) {
                    Text("\(streak.fa) روز پیاپی")
                        .font(.app(.title2))
                        .contentTransition(.numericText())
                    Text(isActiveToday ? "زنجیرهٔ امروز روشن است" : "امروز هنوز تمرین نکرده‌اید")
                        .font(.app(.subheadline))
                        .foregroundStyle(.secondary)
                }
                Spacer(minLength: 0)
                VStack(spacing: Theme.Spacing.xs) {
                    DailyGoalRing(xp: todayXP, goal: dailyGoal, size: 64)
                    Text("هدف روزانه")
                        .font(.app(.caption2))
                        .foregroundStyle(.secondary)
                }
                .accessibilityElement(children: .ignore)
                .accessibilityLabel("هدف روزانه")
                .accessibilityValue("\(todayXP.fa) از \(dailyGoal.fa) امتیاز")
            }
            .accessibilityElement(children: .contain)

            HStack(spacing: Theme.Spacing.s) {
                chip(Label("سطح \(level.fa) · \(LevelText.title(level: level))", systemImage: "star.circle.fill"),
                     tint: Theme.Playful.gold)
                chip(Label("\(freezes.fa) محافظ زنجیره", systemImage: "snowflake"), tint: .cyan)
                Spacer(minLength: 0)
            }

            Text(dueCount > 0 ? "\(dueCount.fa) بیت برای مرور" : "امروز مروری ندارید")
                .font(.app(.subheadline))
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)

            Button(action: onStartReview) {
                Text("شروع مرور")
                    .font(.app(.headline))
                    .frame(maxWidth: .infinity, minHeight: 36)
            }
            .buttonStyle(.glassProminent)
            .controlSize(.large)
            .disabled(dueCount == 0)
        }
        .padding(.vertical, Theme.Spacing.xs)
    }

    private func chip(_ label: Label<Text, Image>, tint: Color) -> some View {
        label
            .font(.app(.caption))
            .lineLimit(1)
            .minimumScaleFactor(0.8)
            .foregroundStyle(tint)
            .padding(.horizontal, Theme.Spacing.s)
            .padding(.vertical, Theme.Spacing.xs)
            .background(tint.opacity(0.14), in: Capsule())
    }
}

#Preview {
    List {
        Section { TodayHeroCard(streak: 7, isActiveToday: true, todayXP: 14, dailyGoal: 20, level: 3,
                                freezes: 1, dueCount: 12, onStartReview: {}) }
        Section { TodayHeroCard(streak: 0, isActiveToday: false, todayXP: 0, dailyGoal: 20, level: 1,
                                freezes: 0, dueCount: 0, onStartReview: {}) }
    }
    .persianRoot()
}
