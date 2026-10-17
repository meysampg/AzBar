import SwiftUI

/// Streak, daily goal and level in three equal columns, with the level progress underneath.
struct TodayStatsCard: View {
    let streak: Int
    let isActiveToday: Bool
    let todayXP: Int
    let dailyGoal: Int
    let levelInfo: LevelInfo
    let freezes: Int

    var body: some View {
        VStack(spacing: Theme.Spacing.m) {
            HStack(alignment: .top, spacing: 0) {
                streakColumn
                divider
                goalColumn
                divider
                levelColumn
            }
            VStack(spacing: Theme.Spacing.xs) {
                AzProgressBar(value: levelInfo.fraction, tint: Theme.Palette.gold, height: 6, label: "پیشرفت سطح")
                Text("\(levelInfo.xpRemaining.fa) امتیاز تا سطح \((levelInfo.level + 1).fa)")
                    .font(.azCaption)
                    .foregroundStyle(Theme.Palette.inkSecondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .azCard()
    }

    private var divider: some View {
        Rectangle().fill(Theme.Palette.hairline).frame(width: 1).frame(maxHeight: 96)
    }

    private var streakColumn: some View {
        VStack(spacing: Theme.Spacing.xs) {
            StreakFlame(streak: streak, isActiveToday: isActiveToday, size: 30)
                .accessibilityHidden(true)
            Text(streak.fa)
                .font(.azNumber)
                .foregroundStyle(Theme.Palette.ink)
                .contentTransition(.numericText())
            Text("روز پیاپی")
                .font(.azCaption)
                .foregroundStyle(Theme.Palette.inkSecondary)
            if freezes > 0 {
                AzChip("\(freezes.fa)", systemImage: "snowflake", tone: .info)
                    .accessibilityLabel("\(freezes.fa) محافظ زنجیره")
            }
        }
        .frame(maxWidth: .infinity)
        .accessibilityElement(children: .combine)
    }

    private var goalColumn: some View {
        VStack(spacing: Theme.Spacing.xs) {
            DailyGoalRing(xp: todayXP, goal: dailyGoal, size: 52)
                .accessibilityHidden(true)
            Text("هدف روزانه")
                .font(.azCaption)
                .foregroundStyle(Theme.Palette.inkSecondary)
        }
        .frame(maxWidth: .infinity)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("هدف روزانه")
        .accessibilityValue("\(todayXP.fa) از \(dailyGoal.fa) امتیاز")
    }

    private var levelColumn: some View {
        VStack(spacing: Theme.Spacing.xs) {
            AzMedallion(diameter: 44, fill: Theme.Palette.teal, edge: Theme.Palette.tealDeep) {
                Text(levelInfo.level.fa)
                    .font(.azHeadline)
                    .foregroundStyle(.white)
            }
            .frame(width: 44, height: 48)
            .accessibilityHidden(true)
            Text("سطح · \(LevelText.title(level: levelInfo.level))")
                .font(.azCaption)
                .foregroundStyle(Theme.Palette.inkSecondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("سطح \(levelInfo.level.fa)، \(LevelText.title(level: levelInfo.level))")
    }
}

#Preview {
    TodayStatsCard(streak: 7, isActiveToday: true, todayXP: 14, dailyGoal: 20,
                   levelInfo: LevelCurve.info(totalXP: 130), freezes: 1)
        .padding(20)
        .azScreenBackground()
        .persianRoot()
}
