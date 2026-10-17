import SwiftUI

struct ProgressHomeView: View {
    @Environment(ProgressStore.self) private var progress
    @Environment(GamificationStore.self) private var gamification

    @State private var selectedBadge: BadgeID?

    var body: some View {
        let snapshot = gamification.snapshot()
        let unlocked = gamification.unlocked()
        ScrollView {
            VStack(alignment: .leading, spacing: Theme.Layout.sectionGap) {
                LevelCard(info: gamification.levelInfo)

                VStack(alignment: .leading, spacing: Theme.Spacing.m) {
                    AzSectionHeader("این هفته")
                    WeekXPBars(week: gamification.weekXP(), goal: gamification.dailyGoal)
                        .azCard()
                }

                VStack(alignment: .leading, spacing: Theme.Spacing.m) {
                    AzSectionHeader("زنجیره")
                    HStack(spacing: Theme.Spacing.m) {
                        StreakFlame(streak: progress.currentStreak(),
                                    isActiveToday: progress.hasActivity(on: .now) || gamification.todayXP > 0, size: 36)
                            .accessibilityHidden(true)
                        VStack(alignment: .leading, spacing: Theme.Spacing.xxs) {
                            Text("\(progress.currentStreak().fa) روز پیاپی")
                                .font(.azHeadline).foregroundStyle(Theme.Palette.ink)
                            Text("بیشترین: \(gamification.longestStreak.fa) روز")
                                .font(.azMeta).foregroundStyle(Theme.Palette.inkSecondary)
                        }
                        Spacer(minLength: 0)
                        AzChip("\(gamification.freezesAvailable.fa) محافظ زنجیره", systemImage: "snowflake", tone: .info)
                    }
                    .azCard()
                    Text("اگر روزی تمرین نکنید، یک محافظ زنجیره را خودکار نگه می‌دارد. هر هفته یک محافظ تازه می‌گیرید (حداکثر ۲).")
                        .font(.azCaption)
                        .foregroundStyle(Theme.Palette.inkSecondary)
                }

                VStack(alignment: .leading, spacing: Theme.Spacing.m) {
                    AzSectionHeader("دستاوردها · \(unlocked.count.fa) از \(BadgeCatalog.all.count.fa)")
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 96), spacing: Theme.Spacing.s)], spacing: Theme.Spacing.s) {
                        ForEach(BadgeCatalog.all) { def in
                            Button { selectedBadge = def.id } label: {
                                BadgeTile(badge: def.id, unlocked: unlocked[def.id] != nil,
                                          progress: BadgeCatalog.progress(def.id, snapshot: snapshot))
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .azCard()
                }

                VStack(alignment: .leading, spacing: Theme.Spacing.m) {
                    AzSectionHeader("آمار")
                    VStack(spacing: 0) {
                        statRow("درس‌های تمام‌شده", snapshot.lessonsCompleted.fa)
                        Divider().overlay(Theme.Palette.hairline)
                        statRow("بیت‌های آموخته", progress.learnedCoupletCount().fa)
                        Divider().overlay(Theme.Palette.hairline)
                        statRow("بیت‌های ماندگار", progress.matureCoupletCount().fa)
                        Divider().overlay(Theme.Palette.hairline)
                        statRow("مرورها", progress.reviewCount().fa)
                    }
                    .azCard(padding: 0)
                }
            }
            .padding(.horizontal, Theme.Layout.margin)
            .padding(.vertical, Theme.Spacing.l)
            .frame(maxWidth: Theme.Layout.readableWidth)
            .frame(maxWidth: .infinity)
        }
        .azScreenBackground()
        .navigationTitle("پیشرفت")
        .sheet(item: $selectedBadge) { badge in
            BadgeDetailView(badge: badge, unlockedAt: unlocked[badge],
                            progress: BadgeCatalog.progress(badge, snapshot: snapshot))
        }
    }
}

private func statRow(_ label: LocalizedStringKey, _ value: String) -> some View {
    HStack {
        Text(label).font(.azBody).foregroundStyle(Theme.Palette.ink)
        Spacer(minLength: Theme.Spacing.s)
        Text(value).font(.azHeadline).foregroundStyle(Theme.Palette.teal)
    }
    .padding(.horizontal, Theme.Layout.cardPadding)
    .padding(.vertical, Theme.Spacing.m)
    .accessibilityElement(children: .combine)
}

extension BadgeID: @retroactive Identifiable {
    public var id: String { rawValue }
}

#Preview {
    PreviewContainer { NavigationStack { ProgressHomeView() } }
}
