import SwiftUI

struct LevelCard: View {
    let info: LevelInfo

    var body: some View {
        VStack(spacing: Theme.Spacing.m) {
            AzMedallion(diameter: 88, fill: Theme.Palette.teal, rim: Theme.Palette.gold, rimWidth: 4,
                        edge: Theme.Palette.tealDeep) {
                Text(info.level.fa)
                    .font(.azDisplay)
                    .foregroundStyle(.white)
                    .contentTransition(.numericText())
            }
            .frame(width: 88, height: 92)
            .accessibilityHidden(true)

            Text("سطح \(info.level.fa) · \(LevelText.title(level: info.level))")
                .font(.azTitle)
                .foregroundStyle(Theme.Palette.ink)
            AzProgressBar(value: info.fraction, tint: Theme.Palette.gold, label: "پیشرفت سطح")
            Text("\(info.xpRemaining.fa) امتیاز تا سطح \((info.level + 1).fa)")
                .font(.azMeta)
                .foregroundStyle(Theme.Palette.inkSecondary)
            Text("\(info.totalXP.fa) امتیاز در مجموع")
                .font(.azCaption)
                .foregroundStyle(Theme.Palette.inkSecondary)
        }
        .frame(maxWidth: .infinity)
        .azCard()
        .accessibilityElement(children: .combine)
    }
}

#Preview {
    LevelCard(info: LevelCurve.info(totalXP: 130))
        .padding(20)
        .azScreenBackground()
        .persianRoot()
}
