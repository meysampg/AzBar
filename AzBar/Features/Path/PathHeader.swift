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
                .font(.app(.title2))
                .accessibilityAddTraits(.isHeader)
            Text("\(poetName) · \(totalCouplets.fa) بیت")
                .font(.app(.subheadline))
                .foregroundStyle(.secondary)
            LessonProgressBar(value: totalCouplets > 0 ? Double(learned) / Double(totalCouplets) : 0)
                .padding(.top, Theme.Spacing.xs)
            HStack {
                Text("\(learned.fa) از \(totalCouplets.fa) بیت آموخته شد")
                Spacer(minLength: Theme.Spacing.s)
                Label("\(crowns.fa) تاج", systemImage: "crown.fill")
                    .foregroundStyle(Theme.Playful.gold)
            }
            .font(.app(.caption))
            .foregroundStyle(.secondary)
        }
        .padding(Theme.Spacing.l)
        .background(.background.secondary, in: .rect(cornerRadius: Theme.Radius.card))
    }
}

#Preview {
    PathHeader(title: "غزل شمارهٔ ۱", poetName: "حافظ", totalCouplets: 7, learned: 3, crowns: 1)
        .padding()
        .persianRoot()
}
