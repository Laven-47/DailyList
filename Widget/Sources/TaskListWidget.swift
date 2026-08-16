import SwiftUI
import WidgetKit

/// 主屏幕小组件（可在编辑小组件时设置"显示已完成任务"）
/// - 小：进度环 + 统计数字，点按打开应用
/// - 中/大：今日任务逐行展示，每行圆形按钮直接切换完成，右上角 "+" 快捷添加
struct TaskListWidget: Widget {
    var body: some WidgetConfiguration {
        AppIntentConfiguration(
            kind: "DailyListTaskList",
            intent: WidgetConfigIntent.self,
            provider: TaskProvider()
        ) { entry in
            TaskListWidgetView(entry: entry)
        }
        .configurationDisplayName("今日任务")
        .description("显示今日任务清单，可直接切换完成状态，点 + 添加任务。长按组件可编辑设置。")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
    }
}

struct TaskListWidgetView: View {
    @Environment(\.widgetFamily) private var family
    let entry: TaskEntry

    private var maxRows: Int {
        switch family {
        case .systemMedium: return 4
        case .systemLarge: return 8
        default: return 0
        }
    }

    /// 按用户配置过滤已完成
    private var displayTasks: [DailyTask] {
        entry.showCompleted ? entry.tasks : entry.tasks.filter { !$0.isDone }
    }

    var body: some View {
        if family == .systemSmall {
            SmallProgressView(entry: entry)
        } else {
            TaskRowsView(entry: entry, displayTasks: displayTasks, maxRows: maxRows)
        }
    }
}

// MARK: - 小尺寸：进度环

private struct SmallProgressView: View {
    let entry: TaskEntry

    private var done: Int { entry.tasks.filter(\.isDone).count }
    private var total: Int { entry.tasks.count }

    var body: some View {
        VStack(spacing: 8) {
            ZStack {
                Circle()
                    .stroke(Color.secondary.opacity(0.25), lineWidth: 7)
                Circle()
                    .trim(from: 0, to: total > 0 ? Double(done) / Double(total) : 0)
                    .stroke(Color.accentColor, style: StrokeStyle(lineWidth: 7, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                Text("\(done)/\(total)")
                    .font(.system(.title2, design: .rounded).bold())
                    .minimumScaleFactor(0.5)
            }
            Text(footer)
                .font(.caption)
                .foregroundColor(.secondary)
                .minimumScaleFactor(0.6)
                .lineLimit(1)
        }
        .widgetURL(URL(string: "dailylist://home"))
        .containerBackground(for: .widget) {
            Rectangle().fill(.ultraThinMaterial)
        }
    }

    private var footer: String {
        if total == 0 { return "点按添加任务" }
        if done == total { return "全部完成 🎉" }
        return "今日任务"
    }
}

// MARK: - 中/大尺寸：任务列表

private struct TaskRowsView: View {
    let entry: TaskEntry
    let displayTasks: [DailyTask]
    let maxRows: Int

    private var done: Int { entry.tasks.filter(\.isDone).count }
    private var total: Int { entry.tasks.count }
    private var shown: [DailyTask] { Array(displayTasks.prefix(maxRows)) }
    private var remaining: Int { max(0, displayTasks.count - shown.count) }

    var body: some View {
        VStack(alignment: .leading, spacing: 7) {
            header
            if displayTasks.isEmpty {
                emptyState
            } else {
                taskRows
            }
        }
        .containerBackground(for: .widget) {
            Rectangle().fill(.ultraThinMaterial)
        }
    }

    private var header: some View {
        HStack(spacing: 6) {
            VStack(alignment: .leading, spacing: 1) {
                Text("今日任务")
                    .font(.headline)
                Text(Self.shortDate)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            Spacer(minLength: 4)
            if total > 0 {
                Text("\(done)/\(total)")
                    .font(.system(.caption, design: .rounded).bold())
                    .foregroundColor(.secondary)
            }
            Button(intent: OpenQuickAddIntent()) {
                Image(systemName: "plus.circle.fill")
                    .font(.title3)
                    .foregroundColor(.accentColor)
            }
            .buttonStyle(.plain)
        }
    }

    private var taskRows: some View {
        VStack(spacing: 0) {
            ForEach(shown) { task in
                HStack(spacing: 9) {
                    Button(intent: ToggleTaskIntent(taskID: task.id)) {
                        ZStack {
                            Circle()
                                .stroke(
                                    task.isDone ? Color.accentColor : Color.secondary.opacity(0.5),
                                    lineWidth: 1.5
                                )
                            if task.isDone {
                                Image(systemName: "checkmark")
                                    .font(.system(size: 9, weight: .bold))
                                    .foregroundColor(.accentColor)
                            }
                        }
                        .frame(width: 20, height: 20)
                    }
                    .buttonStyle(.plain)

                    if task.isStarred && !task.isDone {
                        Image(systemName: "star.fill")
                            .font(.caption2)
                            .foregroundColor(.orange)
                    }

                    Text(task.title)
                        .font(.subheadline)
                        .strikethrough(task.isDone, color: .secondary)
                        .foregroundColor(task.isDone ? .secondary : .primary)
                        .lineLimit(1)

                    Spacer(minLength: 0)
                }
                .padding(.vertical, 4)
            }
            Spacer(minLength: 0)
        }
    }

    private var emptyState: some View {
        VStack(spacing: 8) {
            Spacer()
            Image(systemName: "checklist")
                .font(.system(size: 28))
                .foregroundColor(.secondary)
            Text("还没有任务，点 + 添加")
                .font(.caption)
                .foregroundColor(.secondary)
            Spacer()
        }
        .frame(maxWidth: .infinity)
    }

    private static var shortDate: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "zh_CN")
        formatter.dateFormat = "M月d日 EEE"
        return formatter.string(from: Date())
    }
}
