import SwiftUI

struct BadgeDetailView: View {
    let badge: BadgeID
    let unlockedAt: Date?
    let progress: BadgeProgress

    var body: some View {
        VStack(spacing: Theme.Spacing.m) {
            BadgeMedal(badge: badge, unlocked: unlockedAt != nil, size: 110)
                .padding(.top, Theme.Spacing.xl)
            Text(badge.title).font(.azTitle).foregroundStyle(Theme.Palette.ink)
            Text(badge.detail)
                .font(.azBody)
                .foregroundStyle(Theme.Palette.inkSecondary)
                .multilineTextAlignment(.center)
            if let unlockedAt {
                Text("به دست آمده در \(Self.dateText(unlockedAt))")
                    .font(.azMeta)
                    .foregroundStyle(Theme.Palette.successDeep)
            } else {
                AzProgressBar(value: progress.fraction, tint: badge.tint, height: 10)
                    .padding(.horizontal, Theme.Spacing.xl)
                Text("\(progress.current.fa) از \(progress.target.fa)")
                    .font(.azMeta)
                    .foregroundStyle(Theme.Palette.inkSecondary)
            }
            Spacer(minLength: 0)
        }
        .padding(.horizontal, Theme.Spacing.l)
        .frame(maxWidth: .infinity)
        .azScreenBackground()
        .presentationDetents([.medium])
        .persianRoot()
    }

    private static func dateText(_ date: Date) -> String {
        date.formatted(Date.FormatStyle(date: .long, time: .omitted,
                                        locale: Locale(identifier: "fa_IR"),
                                        calendar: Calendar(identifier: .persian)))
    }
}

#Preview {
    BadgeDetailView(badge: .streak7, unlockedAt: .now, progress: BadgeProgress(current: 7, target: 7))
        .persianRoot()
}
