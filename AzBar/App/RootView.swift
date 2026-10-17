import SwiftUI

struct RootView: View {
    @Environment(AppModel.self) private var model
    @Environment(ProgressStore.self) private var progress
    @Environment(AppSettings.self) private var settings
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
            Tab("تنظیمات", systemImage: "gearshape", value: AppTab.settings) {
                NavigationStack {
                    SettingsView()
                }
            }
        }
        .tabBarMinimizeBehavior(.onScrollDown)
        .background { Color.clear.fullScreenCover(item: $model.learnRequest) { request in LearnView(request: request) } }
        .background { Color.clear.fullScreenCover(isPresented: $model.isReviewPresented) { ReviewSessionView() } }
        .background {
            Color.clear.sheet(isPresented: $model.isFalPresented) {
                FalView()
                    .presentationDetents([.large])
            }
        }
        .onChange(of: scenePhase) { _, phase in
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

#Preview {
    PreviewContainer { RootView() }
}
