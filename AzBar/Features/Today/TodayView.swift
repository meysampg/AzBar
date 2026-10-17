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
        List {
            Section {
                TodayHeroCard(
                    streak: progress.currentStreak(),
                    isActiveToday: progress.hasActivity(on: .now) || gamification.todayXP > 0,
                    todayXP: gamification.todayXP,
                    dailyGoal: gamification.dailyGoal,
                    level: gamification.levelInfo.level,
                    freezes: gamification.freezesAvailable,
                    dueCount: due,
                    onStartReview: { model.isReviewPresented = true }
                )
            }

            if plans.isEmpty {
                Section { emptyState }
                    .listRowBackground(Color.clear)
            } else {
                Section {
                    ForEach(plans, id: \.poemId) { plan in
                        NavigationLink(value: LibraryRoute.path(plan.poemId, poetId: plan.poetId)) {
                            ContinueLearningRow(
                                title: plan.title,
                                poetName: plan.poetName,
                                progress: progress.progress(poemId: plan.poemId, totalMemorizable: plan.memorizableCount),
                                isComplete: plan.nextCoupletIndex < 0,
                                nextLesson: nextLesson(in: paths[plan.poemId]),
                                crowns: paths[plan.poemId]?.filter { $0.state == .mastered }.count ?? 0
                            )
                        }
                        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                            Button("حذف", systemImage: "trash", role: .destructive) {
                                pendingDelete = PendingDelete(poemId: plan.poemId, title: plan.title)
                            }
                        }
                    }
                } header: {
                    Text("در حال حفظ").font(.app(.footnote))
                }
            }

            Section {
                Button {
                    model.isFalPresented = true
                } label: {
                    Label {
                        Text("نیت کنید و دیوان را بگشایید")
                    } icon: {
                        Image(systemName: "sparkles").foregroundStyle(.tint)
                    }
                    .contentShape(.rect)
                }
                .buttonStyle(.plain)
                .accessibilityHint("فال حافظ را باز می‌کند")
            } header: {
                Text("فال حافظ").font(.app(.footnote))
            }

            if !favorites.isEmpty {
                Section {
                    ForEach(favorites, id: \.poemId) { favorite in
                        NavigationLink(value: LibraryRoute.poem(favorite.poemId, poetId: favorite.poetId)) {
                            Label {
                                Text(verbatim: favorite.title)
                            } icon: {
                                Image(systemName: "heart.fill").foregroundStyle(.red)
                            }
                        }
                    }
                } header: {
                    Text("علاقه‌مندی‌ها").font(.app(.footnote))
                }
            }
        }
        .listStyle(.insetGrouped)
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

    private var emptyState: some View {
        ContentUnavailableView {
            Label("هنوز شعری برای حفظ برنگزیده‌اید", systemImage: "text.book.closed")
        } description: {
            Text("از کتابخانه غزلی برگزینید و «حفظ کن» را بزنید")
        } actions: {
            Button("رفتن به کتابخانه") { model.selectedTab = .library }
                .buttonStyle(.glass)
        }
    }
}

#Preview {
    PreviewContainer {
        NavigationStack { TodayView().libraryDestinations() }
    }
}
