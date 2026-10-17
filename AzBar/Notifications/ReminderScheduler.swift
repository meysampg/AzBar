// STUB (WP2): replace implementation, keep signatures
import Foundation
import UserNotifications

@MainActor
final class ReminderScheduler {
    init() {}

    func requestAuthorization() async -> Bool {
        (try? await UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge])) ?? false
    }

    func authorizationStatus() async -> UNAuthorizationStatus {
        await UNUserNotificationCenter.current().notificationSettings().authorizationStatus
    }

    func reschedule(enabled: Bool, hour: Int, minute: Int, store: ProgressStore) async {}
}
