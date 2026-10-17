#if DEBUG
import SwiftUI
import SwiftData

/// Debug-only launch routing and demo data, used to capture README screenshots from a device.
///
/// `-AzBarDemo YES` swaps in an in-memory store seeded through the public store APIs and a throwaway
/// settings suite, so the on-disk store and the real settings are never opened or written.
/// `-AzBarScreen <name>` (demo mode only) then routes straight to a screen:
/// `today`, `library`, `poet:7`, `category:24`, `reader:2130`, `path:2130`, `learn-cloze`, `learn-wordbank`,
/// `learn-fillblank`, `lesson-complete`, `review`, `review-tab`, `progress`, `badge`, `fal`, `fal-result`,
/// `settings`, `about`.
@MainActor
enum DebugLaunch {
    private static let hafez: PoetID = 2
    private static let ghazal: PoemID = 2130

    static var isDemo: Bool { UserDefaults.standard.bool(forKey: "AzBarDemo") }

    static var screen: String? {
        isDemo ? UserDefaults.standard.string(forKey: "AzBarScreen") : nil
    }

    /// Badge shown by the `badge` screen.
    static var badge: BadgeID? { screen == "badge" ? .streak7 : nil }

    static func makeModel() -> AppModel {
        let suiteName = "azbar.demo"
        UserDefaults.standard.removePersistentDomain(forName: suiteName)
        let defaults = UserDefaults(suiteName: suiteName) ?? .standard
        return AppModel(container: AppModel.inMemoryContainer(), content: .live(bundle: .main),
                        settings: AppSettings(defaults: defaults))
    }

    static func run(_ model: AppModel) async {
        guard isDemo else { return }
        await seed(model)
        guard let screen else { return }
        let parts = screen.split(separator: ":", maxSplits: 1).map(String.init)
        let arg = parts.count > 1 ? Int(parts[1]) : nil
        switch parts[0] {
        case "today": model.selectedTab = .today
        case "library": model.selectedTab = .library
        case "poet":
            model.selectedTab = .library
            model.libraryPath = [.poet(arg ?? 7)]
        case "category":
            model.selectedTab = .library
            model.libraryPath = [.category(arg ?? 24, poetId: hafez)]
        case "reader":
            model.selectedTab = .library
            model.libraryPath = [.poem(arg ?? ghazal, poetId: hafez)]
        case "path":
            model.selectedTab = .library
            model.libraryPath = [.path(arg ?? ghazal, poetId: hafez)]
        case "learn-cloze": learn(model, "cloze")
        case "learn-wordbank": learn(model, "wordbank")
        case "learn-fillblank": learn(model, "fillblank")
        case "lesson-complete": learn(model, "complete")
        case "review": model.isReviewPresented = true
        case "review-tab": model.selectedTab = .review
        case "progress", "badge": model.selectedTab = .progress
        case "fal", "fal-result": model.isFalPresented = true
        case "settings", "about": model.selectedTab = .settings
        default: break
        }
    }

    /// Seeding can queue badge toasts; the screenshots should not show them.
    static func finishSeeding(_ gamification: GamificationStore) {
        guard isDemo else { return }
        while !gamification.pendingToasts.isEmpty { gamification.dismissToast() }
    }

    private static func learn(_ model: AppModel, _ target: String) {
        model.selectedTab = .today
        var request = LearnRequest(poemId: ghazal, poetId: hafez)
        request.debugTarget = target
        model.learnRequest = request
    }

    // MARK: Seeding

    private static func seed(_ model: AppModel) async {
        guard let poem = try? await model.content.poem(ghazal, poetId: hafez) else { return }
        let progress = model.progress
        let gamification = model.gamification
        let fsrs = model.settings.fsrsParameters
        let scheduler = FSRSScheduler(parameters: fsrs)
        let cal = Calendar.current
        func day(_ ago: Int, hour: Int = 20) -> Date {
            let start = cal.startOfDay(for: .now)
            let date = cal.date(byAdding: .day, value: -ago, to: start) ?? start
            return min(cal.date(bySettingHour: hour, minute: 15, second: 0, of: date) ?? date, .now)
        }

        progress.addPlan(poem: poem, poetName: "حافظ")
        let indices = poem.memorizableCouplets.map(\.index)
        func key(_ i: Int) -> CoupletKey { CoupletKey(poemId: poem.id, coupletIndex: indices[i]) }
        // Learned over the past week; the older ones are due again today.
        let learned: [(couplet: Int, ago: Int)] = [(0, 6), (1, 5), (2, 4), (3, 2)]
        for item in learned where indices.indices.contains(item.couplet) {
            progress.record(.good, key: key(item.couplet), poetId: hafez, isLearning: true,
                            scheduler: scheduler, now: day(item.ago))
        }
        // Reviews fill the remaining days so the streak runs through today.
        if !indices.isEmpty {
            for ago in [3, 1, 0] {
                progress.record(.good, key: key(0), poetId: hafez, isLearning: false,
                                scheduler: scheduler, now: day(ago, hour: 8))
            }
        }
        if indices.indices.contains(4) { progress.advancePlan(poemId: poem.id, to: indices[4]) }

        // XP history over the past seven days.
        let xpPerDay = [6: 25, 5: 40, 4: 30, 3: 55, 2: 45, 1: 60, 0: 35]
        for (ago, xp) in xpPerDay {
            gamification.award([XPAward(.reviewRated, xp)], now: day(ago, hour: 9))
        }
        for (node, ago) in [("L\(indices.first ?? 0)", 5), ("L\(indices.dropFirst(2).first ?? 2)", 2)] {
            _ = gamification.completeLesson(LessonOutcome(
                poemId: poem.id, nodeId: node, kind: .lesson, gradedCount: 6, mistakes: 0,
                newCouplets: 2, passed: true, finishedAt: day(ago, hour: 21)))
        }
        gamification.recordFalOpened(now: day(1))
        progress.toggleFavorite(poemId: poem.id, poetId: hafez, title: poem.title)
    }
}
#endif
