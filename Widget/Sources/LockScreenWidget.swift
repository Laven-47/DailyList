import SwiftUI
import WidgetKit

/// 锁屏小组件（可在编辑小组件时设置"显示已完成任务"）
/// - 矩形：前几条任务 + 状态圆钮（iOS 26 支持直接点按切换），右上角 "+"
/// - 圆形：进度环 + 完成统计，点按打开应用
/// - 行内：一行文字概要
struct LockScreenWidget: Widget {
    var body: some WidgetConfiguration {
        AppIntentConfiguration(
            kind: "DailyListLockScreen",
            intent: WidgetConfigIntent.self,
            provider: TaskProvider()
        ) { entry in
            LockScreenWidgetView(entry: entry)
        }
        .configurationDisplayName("锁屏任务")
        .description("在锁屏显示今日任务，点按切换完成状态。长按组件可编辑设置。")
        .supportedFamilies([.accessoryRectangular, .accessoryCircular, .accessoryInline])
    }
}

struct LockScreenWidgetView: View {
    @Environment(\.widgetFamily) private var family
    let entry: TaskEntry

    var body: some View {
        switch family {
        case .accessoryRectangular:
            RectangularView(entry: entry)
        case .accessoryCircular:
            CircularView(entry: entry)
        default:
            InlineView(entry: entry)
        }
    }
}

// MARK: - 矩形：任务摘要列表

private struct RectangularView: View {
    let entry: TaskEntry

    private var done: Int { entry.tasks.filter(\.isDone).count }
    private var total: Int { entry.tasks.count }
    private var displayTasks: [DailyTask] {
        entry.showCompleted ? entry.tasks : entry.tasks.filter { !$0.isDone }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 3) {
            HStack(spacing: 5) {
                Text(headerText)
                    .font(.headline)
                Spacer(minLength: 2)
                Button(intent: OpenQuickAddIntent()) {
                    Image(systemName: "plus.circle")
                        .font(.footnote)
                }
                .buttonStyle(.plain)
            }

            if displayTasks.isEmpty {
                Text(entry.tasks.isEmpty ? "点按添加今日任务" : "未完成已清零 🎉")
                    .font(.caption)
                    .foregroundColor(.secondary)
            } else {
                ForEach(displayTasks.prefix(3)) { task in
                    HStack(spacing: 5) {
                        Button(intent: ToggleTaskIntent(taskID: task.id)) {
                            Image(systemName: task.isDone ? "checkmark.circle.fill" : "circle")
                                .font(.footnote)
                        }
                        .buttonStyle(.plain)
                        if task.isStarred && !task.isDone {
                            Image(systemName: "star.fill")
                                .font(.caption2)
                                .foregroundColor(.orange)
                        }
                        Text(task.title)
                            .font(.caption)
                            .lineLimit(1)
                            .strikethrough(task.isDone, color: .secondary)
                    }
                }
            }
        }
        .widgetURL(URL(string: "dailylist://quickadd"))
        .containerBackground(for: .widget) { Color.clear }
    }

    private var headerText: String {
        if total == 0 { return "今日任务" }
        if done == total { return "全部完成 🎉" }
        return "\(done)/\(total)"
    }
}

// MARK: - 圆形：进度环

private struct CircularView: View {
    let entry: TaskEntry

    private var done: Int { entry.tasks.filter(\.isDone).count }
    private var total: Int { entry.tasks.count }

    var body: some View {
        ZStack {
            Circle()
                .stroke(Color.secondary.opacity(0.3), lineWidth: 5)
            Circle()
                .trim(from: 0, to: total > 0 ? Double(done) / Double(total) : 0)
                .stroke(Color.accentColor, style: StrokeStyle(lineWidth: 5, lineCap: .round))
                .rotationEffect(.degrees(-90))
            Text("\(done)/\(total)")
                .font(.system(.footnote, design: .rounded).bold())
                .minimumScaleFactor(0.5)
        }
        .widgetURL(URL(string: "dailylist://home"))
        .containerBackground(for: .widget) { Color.clear }
    }
}

// MARK: - 行内：文字概要

private struct InlineView: View {
    let entry: TaskEntry

    private var done: Int { entry.tasks.filter(\.isDone).count }
    private var total: Int { entry.tasks.count }
    private var next: DailyTask? { entry.tasks.first(where: { !$0.isDone }) }

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: done == total && total > 0 ? "checkmark.seal.fill" : "checklist")
            Text(inlineText)
        }
        .widgetURL(URL(string: "dailylist://home"))
        .containerBackground(for: .widget) { Color.clear }
    }

    private var inlineText: String {
        if total == 0 { return "无任务" }
        let summary = "\(done)/\(total)"
        if let next {
            return "\(summary) · \(next.title)"
        }
        return "\(summary) 全部完成"
    }
}
