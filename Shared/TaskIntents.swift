import AppIntents
import Foundation

/// 小组件上点按任务行的圆形按钮：直接切换完成状态。
/// perform() 在小组件进程内执行，不需要打开应用；执行后系统会自动刷新组件，
/// TaskStore.save 里的 WidgetCenter.reloadAllTimelines() 也兜底刷新所有尺寸的组件。
struct ToggleTaskIntent: AppIntent {
    static let title: LocalizedStringResource = "切换任务完成状态"
    static let description = IntentDescription("在小组件上直接切换任务的完成状态。")

    let taskID: UUID

    init() {
        self.taskID = UUID()
    }

    init(taskID: UUID) {
        self.taskID = taskID
    }

    func perform() async throws -> some IntentResult {
        TaskStore.shared.toggleTask(id: taskID)
        return .result()
    }
}

/// 小组件上点按 "+" 按钮：打开主应用并直达快捷添加界面。
/// openAppWhenRun 为 true 时，perform() 会在主应用进程内执行，
/// 因此这里同时做两件事：发通知（应用存活时立即响应）+ 置标记（应用冷启动时兜底）。
struct OpenQuickAddIntent: AppIntent {
    static let title: LocalizedStringResource = "添加今日任务"
    static let description = IntentDescription("打开 DailyList 并弹出快捷添加界面。")
    static var openAppWhenRun: Bool { true }

    init() {}

    func perform() async throws -> some IntentResult {
        TaskStore.shared.setQuickAddFlag()
        NotificationCenter.default.post(name: .quickAddRequested, object: nil)
        return .result()
    }
}
