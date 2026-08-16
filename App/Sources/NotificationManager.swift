import UserNotifications

/// 每日提醒：纯本地通知（UNCalendarNotificationTrigger），不依赖推送，
/// 免费 Apple ID 签名即可使用。
enum NotificationManager {
    private static let identifier = "dailylist.daily.reminder"
    private static let center = UNUserNotificationCenter.current()

    /// 请求通知权限并调度每日提醒；返回是否成功（用户拒绝则 false）
    @discardableResult
    static func enable(hour: Int, minute: Int) async -> Bool {
        let granted: Bool
        do {
            granted = try await center.requestAuthorization(options: [.alert, .sound, .badge])
        } catch {
            return false
        }
        guard granted else { return false }
        schedule(hour: hour, minute: minute)
        return true
    }

    /// 以当天重复触发的方式调度提醒（覆盖旧的同名通知）
    static func schedule(hour: Int, minute: Int) {
        let content = UNMutableNotificationContent()
        content.title = "DailyList"
        content.body = "看看今天还剩哪些任务没完成吧"
        content.sound = .default

        var components = DateComponents()
        components.hour = hour
        components.minute = minute
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)

        center.removePendingNotificationRequests(withIdentifiers: [identifier])
        center.add(request)
    }

    static func disable() {
        center.removePendingNotificationRequests(withIdentifiers: [identifier])
    }
}
