import Foundation

/// App Group 标识符：主应用与小组件扩展通过它共享数据。
/// 用 Sideloadly 签名时，若高级选项中有 App Groups 设置项，填入同名组即可。
let appGroupID = "group.com.ls.dailylist.shared"

extension Notification.Name {
    /// 小组件上的 "+" 按钮触发：请求主应用弹出快捷添加界面
    static let quickAddRequested = Notification.Name("dailylist.quickAddRequested")
}

/// 单条任务。
/// 注意：刻意不叫 `Task`，避免遮蔽 Swift 并发库的 `Task` 导致 `Task { ... }` 无法编译。
struct DailyTask: Identifiable, Codable, Equatable, Hashable {
    var id: UUID
    var title: String
    var isDone: Bool
    var createdAt: Date
    /// 任务归属日，格式 yyyy-MM-dd
    var day: String
    /// 备注（可选）
    var note: String?
    /// 星标任务：在未完成区置顶显示
    var isStarred: Bool
    /// 完成时间，用于统计与连续打卡；未完成为 nil
    var completedAt: Date?
    /// 手动排序序号（拖拽排序后重写，小在前）
    var sortOrder: Int

    init(
        id: UUID = UUID(),
        title: String,
        isDone: Bool = false,
        createdAt: Date = Date(),
        day: String = DailyTask.todayString(),
        note: String? = nil,
        isStarred: Bool = false,
        completedAt: Date? = nil,
        sortOrder: Int = 0
    ) {
        self.id = id
        self.title = title
        self.isDone = isDone
        self.createdAt = createdAt
        self.day = day
        self.note = note
        self.isStarred = isStarred
        self.completedAt = completedAt
        self.sortOrder = sortOrder
    }

    static func todayString(date: Date = Date()) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: date)
    }

    // MARK: - 解码兼容：旧版本数据缺少新字段时使用默认值

    enum CodingKeys: String, CodingKey {
        case id, title, isDone, createdAt, day, note, isStarred, completedAt, sortOrder
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decodeIfPresent(UUID.self, forKey: .id) ?? UUID()
        title = try c.decodeIfPresent(String.self, forKey: .title) ?? ""
        isDone = try c.decodeIfPresent(Bool.self, forKey: .isDone) ?? false
        createdAt = try c.decodeIfPresent(Date.self, forKey: .createdAt) ?? Date()
        day = try c.decodeIfPresent(String.self, forKey: .day) ?? DailyTask.todayString()
        note = try c.decodeIfPresent(String.self, forKey: .note)
        isStarred = try c.decodeIfPresent(Bool.self, forKey: .isStarred) ?? false
        completedAt = try c.decodeIfPresent(Date.self, forKey: .completedAt)
        sortOrder = try c.decodeIfPresent(Int.self, forKey: .sortOrder) ?? 0
    }
}

extension DailyTask {
    /// 小组件占位/预览用的示例数据
    static let sampleTasks: [DailyTask] = [
        DailyTask(id: UUID(), title: "回复邮件", isDone: true, createdAt: Date(), day: DailyTask.todayString(), completedAt: Date()),
        DailyTask(id: UUID(), title: "健身 30 分钟", isDone: false, createdAt: Date(), day: DailyTask.todayString(), isStarred: true),
        DailyTask(id: UUID(), title: "读书一小时", isDone: false, createdAt: Date(), day: DailyTask.todayString()),
        DailyTask(id: UUID(), title: "买菜", isDone: false, createdAt: Date(), day: DailyTask.todayString(), note: "西红柿、鸡蛋、面条"),
    ]
}
