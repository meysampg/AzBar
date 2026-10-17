import SwiftUI

struct RootView: View {
    @Environment(AppModel.self) private var model
    @Environment(ProgressStore.self) private var progress
    @Environment(AppSettings.self) private var settings
    @Environment(GamificationStore.self) private var gamification
    @Environment(\.scenePhase) private var scenePhase

    private var dueCount: Int {
        let tomorrow = Calendar.current.startOfDay(for: .now).addingTimeInterval(86_400)
        return progress.dueCount(until: tomorrow)
    }

    var body: some View {
        @Bindable var model = model
        TabView(selection: $model.selectedTab) {
            Tab("امروز", systemImage: "sun.max", value: AppTab.today) {
                NavigationStack {
                    TodayView()
                        .libraryDestinations()
                }
            }
            Tab("کتابخانه", systemImage: "books.vertical", value: AppTab.library) {
                NavigationStack {
                    LibraryView()
                        .libraryDestinations()
                }
            }
            Tab("مرور", systemImage: "rectangle.stack", value: AppTab.review) {
                NavigationStack {
                    ReviewHomeView()
                }
            }
            .badge(dueCount > 0 ? Text(dueCount.fa) : nil)
            Tab("پیشرفت", systemImage: "trophy", value: AppTab.progress) {
                NavigationStack {
                    ProgressHomeView()
                }
            }
            Tab("تنظیمات", systemImage: "gearshape", value: AppTab.settings) {
                NavigationStack {
                    SettingsView()
                }
            }
        }
        .tint(Theme.Palette.teal)
        .tabBarMinimizeBehavior(.onScrollDown)
        .background { Color.clear.fullScreenCover(item: $model.learnRequest) { request in LearnView(request: request).persianRoot().preferredColorScheme(.light) } }
        .background { Color.clear.fullScreenCover(isPresented: $model.isReviewPresented) { ReviewSessionView().persianRoot().preferredColorScheme(.light) } }
        .background {
            Color.clear.sheet(isPresented: $model.isFalPresented) {
                FalView()
                    .persianRoot()
                    .preferredColorScheme(.light)
                    .presentationDetents([.large])
            }
        }
        .overlay(alignment: .top) { toastOverlay }
        .task { gamification.reconcile() }
        .onChange(of: scenePhase) { _, phase in
            if phase == .active { gamification.reconcile() }
            guard phase == .background else { return }
            Task {
                await model.reminders.reschedule(
                    enabled: settings.remindersEnabled,
                    hour: settings.reminderHour,
                    minute: settings.reminderMinute,
                    store: progress
                )
            }
        }
    }
}

extension RootView {
    @ViewBuilder
    fileprivate var toastOverlay: some View {
        if let badge = gamification.pendingToasts.first {
            AzToast {
                HStack(spacing: Theme.Spacing.s) {
                    BadgeMedal(badge: badge, unlocked: true, size: 28)
                    Text("دستاورد تازه: \(badge.title)")
                        .font(.app(.subheadline, weight: .semibold))
                        .foregroundStyle(Theme.Palette.ink)
                }
            }
            .padding(.top, Theme.Spacing.s)
            .transition(.move(edge: .top).combined(with: .opacity))
            .accessibilityElement(children: .combine)
            .task(id: badge) {
                try? await Task.sleep(for: .seconds(3))
                guard !Task.isCancelled else { return }
                withAnimation(.smooth) { gamification.dismissToast() }
            }
        }
    }
}

#Preview {
    PreviewContainer { RootView() }
}
