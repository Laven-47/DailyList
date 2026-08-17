import AppIntents
import WidgetKit

struct TaskEntry: TimelineEntry {
    let date: Date
    let tasks: [DailyTask]
    let usesAppGroup: Bool
    let showCompleted: Bool
}

/// 小组件可配置项（长按小组件 → 编辑小组件）
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
    func placeholder(in context: Context) -> TaskEntry {
        TaskEntry(date: Date(), tasks: DailyTask.sampleTasks, usesAppGroup: true, showCompleted: true)
    }

    func snapshot(for configuration: WidgetConfigIntent, in context: Context) async throws -> TaskEntry {
        currentEntry(showCompleted: configuration.showCompleted)
    }

    func timeline(for configuration: WidgetConfigIntent, in context: Context) async throws -> Timeline<TaskEntry> {
        // 跨天后"今日任务"会变化，所以到明天零点后请求一次刷新；
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
