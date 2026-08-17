import AppIntents
import WidgetKit

struct TaskEntry: TimelineEntry {
    let date: Date
    let tasks: [DailyTask]
    let usesAppGroup: Bool
    let showCompleted: Bool
}

/// 小组件可配置项（长按小组件 → 编辑小组件）。
/// 用于 AppIntentConfiguration 的配置 Intent 必须遵循 WidgetConfigurationIntent。
struct WidgetConfigIntent: WidgetConfigurationIntent {
    static let title: LocalizedStringResource = "组件设置"

    @Parameter(title: "显示已完成任务", default: true)
    var showCompleted: Bool

    init() {}

    init(showCompleted: Bool) {
        self.showCompleted = showCompleted
    }
}

struct TaskProvider: AppIntentTimelineProvider {
    // 显式声明关联类型：跨模块 @preconcurrency 协议下编译器有时无法从方法签名推断
    typealias Intent = WidgetConfigIntent
    typealias Entry = TaskEntry

    func placeholder(in context: Context) -> TaskEntry {
        TaskEntry(date: Date(), tasks: DailyTask.sampleTasks, usesAppGroup: true, showCompleted: true)
    }

    func snapshot(for configuration: WidgetConfigIntent, in context: Context) async -> TaskEntry {
        currentEntry(showCompleted: configuration.showCompleted)
    }

    func timeline(for configuration: WidgetConfigIntent, in context: Context) async -> Timeline<TaskEntry> {
        // 跨天后"今日任务"会变化，到明天零点请求一次刷新；
        // 平时的数据变化由每次写入后的 reloadAllTimelines() 驱动。
        var calendar = Calendar.current
        calendar.timeZone = .current
        let nextMidnight = calendar.date(
            byAdding: .day,
            value: 1,
            to: calendar.startOfDay(for: Date())
        ) ?? Date().addingTimeInterval(3600)

        return Timeline(
            entries: [currentEntry(showCompleted: configuration.showCompleted)],
            policy: .after(nextMidnight)
        )
    }

    private func currentEntry(showCompleted: Bool) -> TaskEntry {
        TaskEntry(
            date: Date(),
            tasks: TaskStore.shared.todayTasks(),
            usesAppGroup: TaskStore.shared.isUsingAppGroup,
            showCompleted: showCompleted
        )
    }
}
