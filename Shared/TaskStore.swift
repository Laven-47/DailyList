import Foundation
import WidgetKit

/// 任务数据存取层：主应用与小组件扩展共用同一份代码。
///
/// 数据通过 App Group 的 UserDefaults 共享。若签名方式导致 App Group 不可用
/// （例如免费证书未注册该组），会自动降级到各进程自己的标准存储——
/// 主应用功能完全不受影响，只是小组件与主应用的数据不再互通。
final class TaskStore {
    static let shared = TaskStore()

    private let defaults: UserDefaults
    private static let storageKey = "dailylist.tasks"
    private static let quickAddFlagKey = "dailylist.quickAddFlag"
    private static let reminderEnabledKey = "dailylist.reminder.enabled"
    private static let reminderTimeKey = "dailylist.reminder.time"

    /// App Group 是否真正可用（主应用据此显示诊断提示）
    let isUsingAppGroup: Bool

    private init() {
        if FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: appGroupID) != nil,
           let groupDefaults = UserDefaults(suiteName: appGroupID) {
            isUsingAppGroup = true
            defaults = groupDefaults
        } else {
            isUsingAppGroup = false
            defaults = .standard
        }
    }

    // MARK: - 读取

    func loadTasks() -> [DailyTask] {
        guard let data = defaults.data(forKey: Self.storageKey) else { return [] }
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        guard let tasks = try? decoder.decode([DailyTask].self, from: data) else { return [] }
        return tasks
    }

    /// 今日应展示的任务：今天的全部任务 + 往日未完成的任务（自动顺延）。
    /// 排序：未完成在前；未完成中星标在前、手动序号小在前；
    /// 已完成按完成时间倒序（最近完成的靠前）。
    func todayTasks() -> [DailyTask] {
        let today = DailyTask.todayString()
        return loadTasks()
            .filter { $0.day == today || (!$0.isDone && $0.day < today) }
            .sorted { lhs, rhs in
                if lhs.isDone != rhs.isDone { return !lhs.isDone }
                if lhs.isDone && rhs.isDone {
                    return (lhs.completedAt ?? lhs.createdAt) > (rhs.completedAt ?? rhs.createdAt)
                }
                if lhs.isStarred != rhs.isStarred { return lhs.isStarred }
                if lhs.sortOrder != rhs.sortOrder { return lhs.sortOrder < rhs.sortOrder }
                return lhs.createdAt < rhs.createdAt
            }
    }

    // MARK: - 写入（每次写入后刷新小组件）

    func addTask(_ title: String, isStarred: Bool = false) {
        let trimmed = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        var tasks = loadTasks()
        // 新任务排到未完成区末尾：取当前最大手动序号 +1
        let maxOrder = tasks.map(\.sortOrder).max() ?? 0
        tasks.append(DailyTask(title: trimmed, isStarred: isStarred, sortOrder: maxOrder + 1))
        save(tasks)
    }

    /// 编辑保存（标题/备注/星标等）
    func updateTask(_ updated: DailyTask) {
        var tasks = loadTasks()
        guard let index = tasks.firstIndex(where: { $0.id == updated.id }) else { return }
        tasks[index] = updated
        save(tasks)
    }

    func toggleTask(id: UUID) {
        var tasks = loadTasks()
        guard let index = tasks.firstIndex(where: { $0.id == id }) else { return }
        tasks[index].isDone.toggle()
        tasks[index].completedAt = tasks[index].isDone ? Date() : nil
        save(tasks)
    }

    func toggleStar(id: UUID) {
        var tasks = loadTasks()
        guard let index = tasks.firstIndex(where: { $0.id == id }) else { return }
        tasks[index].isStarred.toggle()
        save(tasks)
    }

    func deleteTask(id: UUID) {
        var tasks = loadTasks()
        tasks.removeAll { $0.id == id }
        save(tasks)
    }

    /// 拖拽排序：按界面上的完整展示顺序重写手动序号
    func reorderToday(_ orderedTasks: [DailyTask]) {
        guard !orderedTasks.isEmpty else { return }
        var tasks = loadTasks()
        for (displayIndex, task) in orderedTasks.enumerated() {
            if let index = tasks.firstIndex(where: { $0.id == task.id }) {
                tasks[index].sortOrder = displayIndex
            }
        }
        save(tasks)
    }

    func clearAll() {
        defaults.removeObject(forKey: Self.storageKey)
        WidgetCenter.shared.reloadAllTimelines()
    }

    private func save(_ tasks: [DailyTask]) {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        if let data = try? encoder.encode(tasks) {
            defaults.set(data, forKey: Self.storageKey)
        }
        WidgetCenter.shared.reloadAllTimelines()
    }

    // MARK: - 统计（连续打卡 / 周完成数 / 累计）

    /// 最近 days 天（含今天）每天的完成数量，按日期从早到晚排列
    func dailyCompletionCounts(days: Int) -> [(date: Date, count: Int)] {
        let calendar = Calendar.current
        let todayStart = calendar.startOfDay(for: Date())
        var counts: [Date: Int] = [:]
        for task in loadTasks() {
            guard let completed = task.completedAt else { continue }
            counts[calendar.startOfDay(for: completed), default: 0] += 1
        }
        var result: [(date: Date, count: Int)] = []
        for offset in stride(from: days - 1, through: 0, by: -1) {
            if let day = calendar.date(byAdding: .day, value: -offset, to: todayStart) {
                result.append((day, counts[day] ?? 0))
            }
        }
        return result
    }

    /// 连续打卡天数：从今天（或昨天）开始往回数，每天都至少完成过一项即 +1
    func streakDays() -> Int {
        let calendar = Calendar.current
        let todayStart = calendar.startOfDay(for: Date())
        var daysWithCompletion: Set<Date> = []
        for task in loadTasks() {
            guard let completed = task.completedAt else { continue }
            daysWithCompletion.insert(calendar.startOfDay(for: completed))
        }
        guard !daysWithCompletion.isEmpty else { return 0 }
        // 今天还没完成不打断连续记录，从昨天起算
        var cursor = daysWithCompletion.contains(todayStart)
            ? todayStart
            : (calendar.date(byAdding: .day, value: -1, to: todayStart) ?? todayStart)
        var streak = 0
        while daysWithCompletion.contains(cursor) {
            streak += 1
            guard let previous = calendar.date(byAdding: .day, value: -1, to: cursor) else { break }
            cursor = previous
        }
        return streak
    }

    func totalCompleted() -> Int {
        loadTasks().filter { $0.completedAt != nil }.count
    }

    // MARK: - 每日提醒设置（应用专用）

    var reminderEnabled: Bool {
        get { defaults.bool(forKey: Self.reminderEnabledKey) }
        set { defaults.set(newValue, forKey: Self.reminderEnabledKey) }
    }

    /// 提醒时刻（默认 9:00），只取小时/分钟参与调度
    var reminderTime: Date {
        get {
            let interval = defaults.double(forKey: Self.reminderTimeKey)
            if interval > 0 { return Date(timeIntervalSince1970: interval) }
            return Calendar.current.date(bySettingHour: 9, minute: 0, second: 0, of: Date()) ?? Date()
        }
        set { defaults.set(newValue.timeIntervalSince1970, forKey: Self.reminderTimeKey) }
    }

    // MARK: - 快捷添加标记

    /// 小组件的 "+" Intent 在打开应用前置位标记，用于冷启动竞态兜底
    func setQuickAddFlag() {
        defaults.set(true, forKey: Self.quickAddFlagKey)
    }

    func consumeQuickAddFlag() -> Bool {
        guard defaults.bool(forKey: Self.quickAddFlagKey) else { return false }
        defaults.removeObject(forKey: Self.quickAddFlagKey)
        return true
    }
}
