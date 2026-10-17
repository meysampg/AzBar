import Testing
import Foundation
@testable import AzBar

@MainActor
struct AppSettingsTests {
    func freshDefaults(_ name: String) -> UserDefaults {
        let d = UserDefaults(suiteName: name)!
        d.removePersistentDomain(forName: name)
        return d
    }

    @Test func defaults() {
        let s = AppSettings(defaults: freshDefaults("azbar.tests.defaults"))
        #expect(s.poemFont == .naskh && s.poemFontSize == 22)
        #expect(s.showMeaning && s.showDiacritics && !s.remindersEnabled)
        #expect(s.reminderHour == 20 && s.reminderMinute == 0)
        #expect(s.preferredReciter == nil)
        #expect(s.newCoupletsPerSession == 2 && s.dailyReviewLimit == 100 && s.desiredRetention == 0.9)
        #expect(s.fsrsParameters.desiredRetention == 0.9)
    }

    @Test func persistsAcrossInstances() {
        let name = "azbar.tests.persist"
        let d = freshDefaults(name)
        let s = AppSettings(defaults: d)
        s.poemFont = .nastaliq
        s.poemFontSize = 30
        s.showMeaning = false
        s.remindersEnabled = true
        s.reminderHour = 7
        s.reminderMinute = 45
        s.preferredReciter = "فریدون فرح‌اندوز"
        s.newCoupletsPerSession = 4
        s.dailyReviewLimit = 50
        s.desiredRetention = 0.85

        let t = AppSettings(defaults: UserDefaults(suiteName: name)!)
        #expect(t.poemFont == .nastaliq && t.poemFontSize == 30 && !t.showMeaning)
        #expect(t.remindersEnabled && t.reminderHour == 7 && t.reminderMinute == 45)
        #expect(t.preferredReciter == "فریدون فرح‌اندوز")
        #expect(t.newCoupletsPerSession == 4 && t.dailyReviewLimit == 50)
        #expect(t.fsrsParameters.desiredRetention == 0.85)
        s.preferredReciter = nil
        #expect(AppSettings(defaults: UserDefaults(suiteName: name)!).preferredReciter == nil)
    }
}
