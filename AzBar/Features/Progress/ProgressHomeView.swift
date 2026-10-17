import SwiftUI

struct ProgressHomeView: View {
    @Environment(ProgressStore.self) private var progress
    @Environment(GamificationStore.self) private var gamification

    @State private var selectedBadge: BadgeID?

    var body: some View {
        let snapshot = gamification.snapshot()
        let unlocked = gamification.unlocked()
        List {
            Section { LevelCard(info: gamification.levelInfo) }

            Section {
                WeekXPBars(week: gamification.weekXP(), goal: gamification.dailyGoal)
                    .padding(.vertical, Theme.Spacing.xs)
            } header: {
                Text("این هفته").font(.app(.footnote))
            }

            Section {
                HStack(spacing: Theme.Spacing.m) {
                    StreakFlame(streak: progress.currentStreak(),
                                isActiveToday: progress.hasActivity(on: .now) || gamification.todayXP > 0, size: 36)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("\(progress.currentStreak().fa) روز پیاپی").font(.app(.headline))
                        Text("بیشترین: \(gamification.longestStreak.fa) روز")
                            .font(.app(.subheadline)).foregroundStyle(.secondary)
                    }
                    Spacer(minLength: 0)
                    Label("\(gamification.freezesAvailable.fa) محافظ زنجیره", systemImage: "snowflake")
                        .font(.app(.caption))
                        .foregroundStyle(.cyan)
                }
            } header: {
                Text("زنجیره").font(.app(.footnote))
            } footer: {
                Text("اگر روزی تمرین نکنید، یک محافظ زنجیره را خودکار نگه می‌دارد. هر هفته یک محافظ تازه می‌گیرید (حداکثر ۲).")
                    .font(.app(.footnote))
            }

            Section {
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 96), spacing: Theme.Spacing.s)], spacing: Theme.Spacing.s) {
                    ForEach(BadgeCatalog.all) { def in
                        Button { selectedBadge = def.id } label: {
                            BadgeTile(badge: def.id, unlocked: unlocked[def.id] != nil,
                                      progress: BadgeCatalog.progress(def.id, snapshot: snapshot))
                        }
                        .buttonStyle(.plain)
                    }
                }
            } header: {
                Text("دستاوردها · \(unlocked.count.fa) از \(BadgeCatalog.all.count.fa)").font(.app(.footnote))
            }

            Section {
                LabeledContent("درس‌های تمام‌شده", value: snapshot.lessonsCompleted.fa)
                LabeledContent("بیت‌های آموخته", value: progress.learnedCoupletCount().fa)
                LabeledContent("بیت‌های ماندگار", value: progress.matureCoupletCount().fa)
                LabeledContent("مرورها", value: progress.reviewCount().fa)
            } header: {
                Text("آمار").font(.app(.footnote))
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle("پیشرفت")
        .sheet(item: $selectedBadge) { badge in
            BadgeDetailView(badge: badge, unlockedAt: unlocked[badge],
                            progress: BadgeCatalog.progress(badge, snapshot: snapshot))
        }
    }
}

extension BadgeID: @retroactive Identifiable {
    public var id: String { rawValue }
}

#Preview {
    PreviewContainer { NavigationStack { ProgressHomeView() } }
}
