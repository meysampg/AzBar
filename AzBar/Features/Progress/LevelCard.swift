import SwiftUI

struct LevelCard: View {
    let info: LevelInfo

    var body: some View {
        VStack(spacing: Theme.Spacing.m) {
            ZStack {
                Circle().fill(LinearGradient(colors: [Theme.Playful.gold, Theme.Playful.xp],
                                             startPoint: .top, endPoint: .bottom))
                Text(info.level.fa)
                    .font(.app(.largeTitle))
                    .foregroundStyle(.white)
                    .contentTransition(.numericText())
            }
            .frame(width: 96, height: 96)
            .accessibilityHidden(true)

            Text("سطح \(info.level.fa) · \(LevelText.title(level: info.level))")
                .font(.app(.title3))
            LessonProgressBar(value: info.fraction, tint: Theme.Playful.xp)
            Text("\(info.xpRemaining.fa) امتیاز تا سطح \((info.level + 1).fa)")
                .font(.app(.subheadline))
                .foregroundStyle(.secondary)
            Text("\(info.totalXP.fa) امتیاز در مجموع")
                .font(.app(.caption))
                .foregroundStyle(.tertiary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, Theme.Spacing.s)
        .accessibilityElement(children: .combine)
    }
}

#Preview {
    List { Section { LevelCard(info: LevelCurve.info(totalXP: 130)) } }.persianRoot()
}
