import SwiftUI

struct TodayView: View {
    @Environment(AppModel.self) private var model
    @Environment(ProgressStore.self) private var progress
    @Environment(GamificationStore.self) private var gamification
    @Environment(\.contentRepository) private var content

    private struct PendingDelete: Identifiable {
        let poemId: PoemID
        let title: String
        var id: PoemID { poemId }
    }

    @State private var pendingDelete: PendingDelete?
    @State private var paths: [PoemID: [PathNode]] = [:]

    var body: some View {
        let plans = progress.activePlans()
        let due = progress.dueCount(until: ReviewQueueWindow.endOfToday())
        let favorites = progress.favorites()
        ScrollView {
            VStack(alignment: .leading, spacing: Theme.Layout.sectionGap) {
                TodayStatsCard(
                    streak: progress.currentStreak(),
                    isActiveToday: progress.hasActivity(on: .now) || gamification.todayXP > 0,
                    todayXP: gamification.todayXP,
                    dailyGoal: gamification.dailyGoal,
                    levelInfo: gamification.levelInfo,
                    freezes: gamification.freezesAvailable
                )

                reviewCard(due: due)

                if plans.isEmpty {
                    emptyState
                } else {
                    VStack(alignment: .leading, spacing: Theme.Spacing.m) {
                        AzSectionHeader("در حال حفظ")
                        ForEach(plans, id: \.poemId) { plan in
                            NavigationLink(value: LibraryRoute.path(plan.poemId, poetId: plan.poetId)) {
                                ContinueLearningCard(
                                    title: plan.title,
                                    poetName: plan.poetName,
                                    progress: progress.progress(poemId: plan.poemId, totalMemorizable: plan.memorizableCount),
                                    isComplete: plan.nextCoupletIndex < 0,
                                    nextLesson: nextLesson(in: paths[plan.poemId]),
                                    crowns: paths[plan.poemId]?.filter { $0.state == .mastered }.count ?? 0
                                )
                            }
                            .buttonStyle(.plain)
                            .contextMenu {
                                Button("حذف", systemImage: "trash", role: .destructive) {
                                    pendingDelete = PendingDelete(poemId: plan.poemId, title: plan.title)
                                }
                            }
                        }
                    }
                }

                falCard

                if !favorites.isEmpty {
                    VStack(alignment: .leading, spacing: Theme.Spacing.m) {
                        AzSectionHeader("علاقه‌مندی‌ها")
                        VStack(spacing: 0) {
                            ForEach(Array(favorites.enumerated()), id: \.element.poemId) { index, favorite in
                                if index > 0 { Divider().overlay(Theme.Palette.hairline) }
                                NavigationLink(value: LibraryRoute.poem(favorite.poemId, poetId: favorite.poetId)) {
                                    HStack(spacing: Theme.Spacing.m) {
                                        Image(systemName: "heart.fill")
                                            .foregroundStyle(Theme.Palette.rose)
                                            .accessibilityHidden(true)
                                        Text(verbatim: favorite.title)
                                            .font(.azBody)
                                            .foregroundStyle(Theme.Palette.ink)
                                            .frame(maxWidth: .infinity, alignment: .leading)
                                        Image(systemName: "chevron.forward")
                                            .font(.azCaption)
                                            .foregroundStyle(Theme.Palette.inkTertiary)
                                            .accessibilityHidden(true)
                                    }
                                    .padding(.horizontal, Theme.Layout.cardPadding)
                                    .padding(.vertical, Theme.Spacing.m)
                                    .contentShape(.rect)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .azCard(padding: 0)
                    }
                }
            }
            .padding(.horizontal, Theme.Layout.margin)
            .padding(.vertical, Theme.Spacing.l)
            .frame(maxWidth: Theme.Layout.readableWidth)
            .frame(maxWidth: .infinity)
        }
        .azScreenBackground()
        .navigationTitle("امروز")
        .confirmationDialog(
            "این شعر از فهرست حفظ حذف شود؟",
            isPresented: Binding(get: { pendingDelete != nil }, set: { if !$0 { pendingDelete = nil } }),
            titleVisibility: .visible,
            presenting: pendingDelete
        ) { item in
            Button("حذف «\(item.title)»", role: .destructive) {
                progress.removePlan(poemId: item.poemId)
            }
            Button("انصراف", role: .cancel) {}
        } message: { _ in
            Text("پیشرفت شما در این شعر هم پاک می‌شود.")
        }
        .sensoryFeedback(.warning, trigger: pendingDelete?.poemId)
        .task(id: PathReloadKey(plans: plans.map(\.poemId), progress: progress.revision, gamification: gamification.revision)) {
            await loadPaths(plans)
        }
    }

    private struct PathReloadKey: Hashable {
        let plans: [PoemID]
        let progress: Int
        let gamification: Int
    }

    private func loadPaths(_ plans: [MemorizationPlan]) async {
        var result: [PoemID: [PathNode]] = [:]
        for plan in plans {
            guard let poem = try? await content.poem(plan.poemId, poetId: plan.poetId) else { continue }
            result[plan.poemId] = gamification.path(for: poem)
        }
        paths = result
    }

    private func nextLesson(in nodes: [PathNode]?) -> (current: Int, total: Int)? {
        guard let nodes, let current = LearningPath.currentNode(in: nodes)?.lessonNumber else { return nil }
        return (current, nodes.filter { $0.kind == .lesson }.count)
    }

    private func reviewCard(due: Int) -> some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.m) {
            HStack(spacing: Theme.Spacing.m) {
                AzIconBadge("rectangle.stack.fill", tone: .teal, size: 44)
                    .accessibilityHidden(true)
                VStack(alignment: .leading, spacing: Theme.Spacing.xxs) {
                    Text(due > 0 ? "\(due.fa) بیت برای مرور" : "امروز مروری ندارید")
                        .font(.azHeadline)
                        .foregroundStyle(Theme.Palette.ink)
                    Text(reviewSubtitle(due: due))
                        .font(.azMeta)
                        .foregroundStyle(Theme.Palette.inkSecondary)
                }
                Spacer(minLength: 0)
            }
            if due > 0 {
                Button("شروع مرور") { model.isReviewPresented = true }
                    .buttonStyle(.azPrimary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .azCard()
    }

    private func reviewSubtitle(due: Int) -> String {
        if due > 0 { return "مرور کوتاه، حافظه را تازه نگه می‌دارد" }
        if let next = progress.nextDueDate() { return "مرور بعدی: \(Self.relative(next))" }
        return "شعری را به فهرست حفظ بیفزایید تا مرور آغاز شود."
    }

    private static func relative(_ date: Date) -> String {
        let style = Date.RelativeFormatStyle(
            presentation: .named, unitsStyle: .wide,
            locale: Locale(identifier: "fa_IR"), calendar: Calendar(identifier: .persian)
        )
        return date.formatted(style)
    }

    private var falCard: some View {
        Button {
            model.isFalPresented = true
        } label: {
            HStack(spacing: Theme.Spacing.m) {
                AzIconBadge("sparkles", tone: .gold, size: 44)
                    .accessibilityHidden(true)
                VStack(alignment: .leading, spacing: Theme.Spacing.xxs) {
                    Text("فال حافظ").font(.azHeadline).foregroundStyle(Theme.Palette.ink)
                    Text("نیت کنید و دیوان را بگشایید").font(.azMeta).foregroundStyle(Theme.Palette.inkSecondary)
                }
                Spacer(minLength: 0)
                Image(systemName: "chevron.forward")
                    .font(.azCaption)
                    .foregroundStyle(Theme.Palette.goldDeep)
                    .accessibilityHidden(true)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .azCard(fill: Theme.Palette.goldSoft, bordered: false)
            .contentShape(.rect)
        }
        .buttonStyle(.plain)
        .accessibilityHint("فال حافظ را باز می‌کند")
    }

    private var emptyState: some View {
        AzEmptyState("text.book.closed", "هنوز شعری برای حفظ برنگزیده‌اید",
                     "از کتابخانه شعری برگزینید و «حفظ کن» را بزنید", "رفتن به کتابخانه") {
            model.selectedTab = .library
        }
        .frame(maxWidth: .infinity)
        .azCard()
    }
}

#Preview {
    PreviewContainer {
        NavigationStack { TodayView().libraryDestinations() }
    }
}
