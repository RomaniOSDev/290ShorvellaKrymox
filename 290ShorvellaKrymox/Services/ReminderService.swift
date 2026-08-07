import Foundation
import UserNotifications

enum ReminderService {
    static let notificationId = "lifeease.daily.mood"

    static var isEnabled: Bool {
        get {
            if UserDefaults.standard.object(forKey: "le_reminder_enabled") == nil { return false }
            return UserDefaults.standard.bool(forKey: "le_reminder_enabled")
        }
        set { UserDefaults.standard.set(newValue, forKey: "le_reminder_enabled") }
    }

    static var hour: Int {
        get {
            let value = UserDefaults.standard.integer(forKey: "le_reminder_hour")
            return value == 0 && UserDefaults.standard.object(forKey: "le_reminder_hour") == nil ? 20 : value
        }
        set { UserDefaults.standard.set(newValue, forKey: "le_reminder_hour") }
    }

    static var minute: Int {
        get { UserDefaults.standard.integer(forKey: "le_reminder_minute") }
        set { UserDefaults.standard.set(newValue, forKey: "le_reminder_minute") }
    }

    static func requestAuthorizationIfNeeded(completion: ((Bool) -> Void)? = nil) {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            switch settings.authorizationStatus {
            case .authorized, .provisional, .ephemeral:
                DispatchQueue.main.async { completion?(true) }
            case .notDetermined:
                UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, _ in
                    DispatchQueue.main.async { completion?(granted) }
                }
            default:
                DispatchQueue.main.async { completion?(false) }
            }
        }
    }

    static func refreshSchedule() {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [notificationId])
        guard isEnabled else { return }

        var date = DateComponents()
        date.hour = hour
        date.minute = minute

        let content = UNMutableNotificationContent()
        content.title = "Shorvella Krymox"
        content.body = "Take a moment to log your mood."
        content.sound = HapticService.soundEnabled ? .default : nil

        let trigger = UNCalendarNotificationTrigger(dateMatching: date, repeats: true)
        let request = UNNotificationRequest(identifier: notificationId, content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(request)
    }

    static func setEnabled(_ enabled: Bool, completion: ((Bool) -> Void)? = nil) {
        if enabled {
            requestAuthorizationIfNeeded { granted in
                isEnabled = granted
                refreshSchedule()
                completion?(granted)
            }
        } else {
            isEnabled = false
            refreshSchedule()
            completion?(true)
        }
    }

    static func updateTime(hour: Int, minute: Int) {
        self.hour = hour
        self.minute = minute
        if isEnabled { refreshSchedule() }
    }
}
