import SwiftUI

@MainActor @Observable
final class AppSettings {
    private let defaults: UserDefaults

    var poemFont: PoemFont { didSet { defaults.set(poemFont.rawValue, forKey: "settings.poemFont") } }
    var poemFontSize: Double { didSet { defaults.set(poemFontSize, forKey: "settings.poemFontSize") } }
    var showMeaning: Bool { didSet { defaults.set(showMeaning, forKey: "settings.showMeaning") } }
    var showDiacritics: Bool { didSet { defaults.set(showDiacritics, forKey: "settings.showDiacritics") } }
    var remindersEnabled: Bool { didSet { defaults.set(remindersEnabled, forKey: "settings.remindersEnabled") } }
    var reminderHour: Int { didSet { defaults.set(reminderHour, forKey: "settings.reminderHour") } }
    var reminderMinute: Int { didSet { defaults.set(reminderMinute, forKey: "settings.reminderMinute") } }
    var preferredReciter: String? { didSet { defaults.set(preferredReciter, forKey: "settings.preferredReciter") } }
    var newCoupletsPerSession: Int { didSet { defaults.set(newCoupletsPerSession, forKey: "settings.newCoupletsPerSession") } }
    var dailyReviewLimit: Int { didSet { defaults.set(dailyReviewLimit, forKey: "settings.dailyReviewLimit") } }
    var desiredRetention: Double { didSet { defaults.set(desiredRetention, forKey: "settings.desiredRetention") } }
    var dailyXPGoal: Int { didSet { defaults.set(dailyXPGoal, forKey: "settings.dailyXPGoal") } }
    var soundsEnabled: Bool { didSet { defaults.set(soundsEnabled, forKey: "settings.soundsEnabled") } }
    var exercisesEnabled: Bool { didSet { defaults.set(exercisesEnabled, forKey: "settings.exercisesEnabled") } }

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        poemFont = defaults.string(forKey: "settings.poemFont").flatMap(PoemFont.init(rawValue:)) ?? .naskh
        poemFontSize = defaults.object(forKey: "settings.poemFontSize") as? Double ?? 22
        showMeaning = defaults.object(forKey: "settings.showMeaning") as? Bool ?? true
        showDiacritics = defaults.object(forKey: "settings.showDiacritics") as? Bool ?? true
        remindersEnabled = defaults.object(forKey: "settings.remindersEnabled") as? Bool ?? false
        reminderHour = defaults.object(forKey: "settings.reminderHour") as? Int ?? 20
        reminderMinute = defaults.object(forKey: "settings.reminderMinute") as? Int ?? 0
        preferredReciter = defaults.string(forKey: "settings.preferredReciter")
        newCoupletsPerSession = defaults.object(forKey: "settings.newCoupletsPerSession") as? Int ?? 2
        dailyReviewLimit = defaults.object(forKey: "settings.dailyReviewLimit") as? Int ?? 100
        desiredRetention = defaults.object(forKey: "settings.desiredRetention") as? Double ?? 0.9
        dailyXPGoal = defaults.object(forKey: "settings.dailyXPGoal") as? Int ?? DailyGoal.defaultGoal
        soundsEnabled = defaults.object(forKey: "settings.soundsEnabled") as? Bool ?? true
        exercisesEnabled = defaults.object(forKey: "settings.exercisesEnabled") as? Bool ?? true
    }

    var fsrsParameters: FSRSParameters {
        FSRSParameters(desiredRetention: desiredRetention)
    }
}
