import SwiftUI

struct TodayView: View {
    @Environment(AppModel.self) private var model
    @Environment(ProgressStore.self) private var progress

    private struct PendingDelete: Identifiable {
        let poemId: PoemID
        let title: String
        var id: PoemID { poemId }
    }

    @State private var pendingDelete: PendingDelete?

    var body: some View {
        let plans = progress.activePlans()
        let due = progress.dueCount(until: ReviewQueueWindow.endOfToday())
        let favorites = progress.favorites()
        List {
            Section {
                StreakCard(
                    streak: progress.currentStreak(),
                    dueCount: due,
                    hasActivityToday: progress.hasActivity(on: .now),
                    onStartReview: { model.isReviewPresented = true }
                )
            }

            if plans.isEmpty {
                Section { emptyState }
                    .listRowBackground(Color.clear)
            } else {
                Section {
                    ForEach(plans, id: \.poemId) { plan in
                        ContinueLearningRow(
                            title: plan.title,
                            poetName: plan.poetName,
                            progress: progress.progress(poemId: plan.poemId, totalMemorizable: plan.memorizableCount),
                            isComplete: plan.nextCoupletIndex < 0
                        ) {
                            model.startLearning(poemId: plan.poemId, poetId: plan.poetId)
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
