import SwiftUI
import UserNotifications

// MARK: - Notification Manager
@MainActor
class NotificationManager: NSObject, ObservableObject, UNUserNotificationCenterDelegate {
    static let shared = NotificationManager()
    
    @Published var notificationSettings: NotificationSettings = NotificationSettings()
    @Published var scheduledNotifications: [ScheduledNotification] = []
    @Published var isAuthorized = false
    
    override init() {
        super.init()
        UNUserNotificationCenter.current().delegate = self
        checkAuthorizationStatus()
    }
    
    // MARK: - Authorization
    func requestAuthorization() async {
        do {
            isAuthorized = try await UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge])
        } catch {
            print("Failed to request notification authorization: \(error)")
        }
    }
    
    func checkAuthorizationStatus() {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            Task { @MainActor in
                self.isAuthorized = settings.authorizationStatus == .authorized
            }
        }
    }
    
    // MARK: - Schedule Notifications
    func scheduleHabitReminder(habitName: String, time: Date) {
        let content = UNMutableNotificationContent()
        content.title = "Time for: \(habitName)"
        content.body = "Let's keep your streak going! 🔥"
        content.sound = .default
        content.badge = NSNumber(value: UIApplication.shared.applicationIconBadgeNumber + 1)
        
        // Custom data
        content.userInfo = ["type": "habit_reminder", "habitName": habitName]
        
        // Add badge
        content.badge = NSNumber(value: 1)
        
        // Trigger
        let calendar = Calendar.current
        let components = calendar.dateComponents([.hour, .minute], from: time)
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
        
        // Request
        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Error scheduling notification: \(error)")
            }
        }
        
        let scheduled = ScheduledNotification(
            title: content.title,
            body: content.body,
            scheduledTime: time,
            type: .habitReminder
        )
        scheduledNotifications.append(scheduled)
    }
    
    func scheduleFocusReminder(time: Date) {
        let content = UNMutableNotificationContent()
        content.title = "Time to Focus"
        content.body = "Start your focus session and crush your goals! 💪"
        content.sound = .default
        content.userInfo = ["type": "focus_reminder"]
        
        let calendar = Calendar.current
        let components = calendar.dateComponents([.hour, .minute], from: time)
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
        
        let request = UNNotificationRequest(identifier: "focus_reminder", content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Error scheduling focus reminder: \(error)")
            }
        }
        
        let scheduled = ScheduledNotification(
            title: content.title,
            body: content.body,
            scheduledTime: time,
            type: .focusReminder
        )
        scheduledNotifications.append(scheduled)
    }
    
    func scheduleMotivationalBoost(time: Date, message: String) {
        let content = UNMutableNotificationContent()
        content.title = "💪 Motivation Boost"
        content.body = message
        content.sound = .default
        content.userInfo = ["type": "motivation"]
        
        let calendar = Calendar.current
        let components = calendar.dateComponents([.hour, .minute], from: time)
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
        
        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Error scheduling motivation notification: \(error)")
            }
        }
        
        let scheduled = ScheduledNotification(
            title: content.title,
            body: content.body,
            scheduledTime: time,
            type: .motivation
        )
        scheduledNotifications.append(scheduled)
    }
    
    func scheduleStreakReminder(day: Int, streakCount: Int) {
        let content = UNMutableNotificationContent()
        content.title = "🔥 Keep Your Streak Alive!"
        content.body = "Day \(streakCount) - Don't break the chain! Complete today's habits."
        content.sound = .default
        content.badge = NSNumber(value: 1)
        
        // Schedule for 6 PM
        var components = DateComponents()
        components.hour = 18
        components.minute = 0
        
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
        let request = UNNotificationRequest(identifier: "streak_\(day)", content: content, trigger: trigger)
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Error scheduling streak reminder: \(error)")
            }
        }
        
        let scheduled = ScheduledNotification(
            title: content.title,
            body: content.body,
            scheduledTime: Date(),
            type: .streak
        )
        scheduledNotifications.append(scheduled)
    }
    
    // MARK: - Delegate Methods
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        completionHandler([.banner, .sound, .badge])
    }
    
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        let userInfo = response.notification.request.content.userInfo
        
        if let type = userInfo["type"] as? String {
            handleNotificationTap(type: type, userInfo: userInfo)
        }
        
        completionHandler()
    }
    
    private func handleNotificationTap(type: String, userInfo: [AnyHashable: Any]) {
        switch type {
        case "habit_reminder":
            if let habitName = userInfo["habitName"] as? String {
                print("User tapped habit reminder for: \(habitName)")
            }
        case "focus_reminder":
            print("User tapped focus reminder")
        case "motivation":
            print("User tapped motivation notification")
        case "streak":
            print("User tapped streak reminder")
        default:
            break
        }
    }
    
    // MARK: - Cancel Notifications
    func cancelAllNotifications() {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
        scheduledNotifications.removeAll()
    }
    
    func cancelNotification(withIdentifier identifier: String) {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [identifier])
        scheduledNotifications.removeAll { $0.id.uuidString == identifier }
    }
}

// MARK: - Notification Models
struct NotificationSettings: Codable {
    var enableHabitReminders: Bool = true
    var enableFocusReminders: Bool = true
    var enableMoodReminders: Bool = true
    var enableMotivationalBoosts: Bool = true
    var enableStreakReminders: Bool = true
    var quietHours: QuietHours = QuietHours()
    var soundEnabled: Bool = true
    var hapticFeedback: Bool = true
}

struct QuietHours: Codable {
    var enabled: Bool = false
    var startTime: Date = {
        var components = DateComponents()
        components.hour = 21
        return Calendar.current.date(from: components) ?? Date()
    }()
    var endTime: Date = {
        var components = DateComponents()
        components.hour = 8
        return Calendar.current.date(from: components) ?? Date()
    }()
}

struct ScheduledNotification: Identifiable {
    let id = UUID()
    let title: String
    let body: String
    let scheduledTime: Date
    let type: NotificationType
}

enum NotificationType: String {
    case habitReminder = "habit_reminder"
    case focusReminder = "focus_reminder"
    case moodReminder = "mood_reminder"
    case motivation = "motivation"
    case streak = "streak"
}

// MARK: - Notification Preferences View
struct NotificationPreferencesView: View {
    @EnvironmentObject var notificationManager: NotificationManager
    @State private var localSettings = NotificationSettings()
    
    var body: some View {
        Form {
            Section("Reminders") {
                Toggle("Habit Reminders", isOn: $localSettings.enableHabitReminders)
                Toggle("Focus Reminders", isOn: $localSettings.enableFocusReminders)
                Toggle("Mood Check-ins", isOn: $localSettings.enableMoodReminders)
                Toggle("Motivational Boosts", isOn: $localSettings.enableMotivationalBoosts)
                Toggle("Streak Reminders", isOn: $localSettings.enableStreakReminders)
            }
            
            Section("Sound & Haptics") {
                Toggle("Sound", isOn: $localSettings.soundEnabled)
                Toggle("Haptic Feedback", isOn: $localSettings.hapticFeedback)
            }
            
            Section("Quiet Hours") {
                Toggle("Enable Quiet Hours", isOn: $localSettings.quietHours.enabled)
                
                if localSettings.quietHours.enabled {
                    DatePicker("Start Time", selection: $localSettings.quietHours.startTime, displayedComponents: .hourAndMinute)
                    DatePicker("End Time", selection: $localSettings.quietHours.endTime, displayedComponents: .hourAndMinute)
                }
            }
        }
        .navigationTitle("Notifications")
        .onAppear {
            localSettings = notificationManager.notificationSettings
        }
        .onDisappear {
            notificationManager.notificationSettings = localSettings
        }
    }
}
