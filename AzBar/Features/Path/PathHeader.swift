import SwiftUI

/// Title block above the learning path.
struct PathHeader: View {
    let title: String
    let poetName: String
    let totalCouplets: Int
    let learned: Int
    let crowns: Int

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.s) {
            Text(verbatim: title)
                .font(.azTitle)
                .foregroundStyle(Theme.Palette.ink)
                .accessibilityAddTraits(.isHeader)
            Text("\(poetName) · \(totalCouplets.fa) بیت")
                .font(.azMeta)
                .foregroundStyle(Theme.Palette.inkSecondary)
            AzProgressBar(value: totalCouplets > 0 ? Double(learned) / Double(totalCouplets) : 0,
                          label: "پیشرفت شعر")
                .padding(.top, Theme.Spacing.xs)
            HStack {
                Text("\(learned.fa) از \(totalCouplets.fa) بیت آموخته شد")
                Spacer(minLength: Theme.Spacing.s)
                if crowns > 0 {
                    Label("\(crowns.fa) تاج", systemImage: "crown.fill")
                        .foregroundStyle(Theme.Palette.goldDeep)
                }
            }
            .font(.azCaption)
            .foregroundStyle(Theme.Palette.inkSecondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .azCard()
    }
}

#Preview {
    PathHeader(title: "غزل شمارهٔ ۱", poetName: "حافظ", totalCouplets: 7, learned: 3, crowns: 1)
        .padding()
        .azScreenBackground()
        .persianRoot()
}
