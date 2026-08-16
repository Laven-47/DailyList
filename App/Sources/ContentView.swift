import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var model: TaskViewModel
    @State private var showStats = false
    @State private var showSettings = false

    var body: some View {
        NavigationStack {
            List {
                Section {
                    TodayHeaderView(
                        done: model.doneTasks.count,
                        total: model.tasks.count,
                        streak: TaskStore.shared.streakDays()
                    )
                    .listRowInsets(EdgeInsets())
                    .listRowBackground(Color.clear)
                    .listRowSeparator(.hidden)
                }

                if !model.usesAppGroup {
                    Section {
                        Text("提示：小组件数据共享未生效（App Group 不可用），应用本身不受影响。解决方法见 README 的 Sideloadly 设置说明。")
                            .font(.footnote)
                            .foregroundColor(.orange)
                    }
                }

                undoneSection

                if !model.doneTasks.isEmpty {
                    doneSection
                }
            }
            .listStyle(.insetGrouped)
            .navigationTitle("DailyList")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        showStats = true
                    } label: {
                        Image(systemName: "chart.bar")
                    }
                }
                ToolbarItemGroup(placement: .topBarTrailing) {
                    EditButton()
                    Button {
                        showSettings = true
                    } label: {
                        Image(systemName: "gearshape")
                    }
                    Button {
                        model.showQuickAdd = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $model.showQuickAdd) {
                QuickAddSheet()
                    .environmentObject(model)
            }
            .sheet(item: $model.editingTask) { task in
                EditTaskSheet(task: task)
                    .environmentObject(model)
            }
            .sheet(isPresented: $showStats) {
                StatsView()
            }
            .sheet(isPresented: $showSettings) {
                SettingsView()
                    .environmentObject(model)
            }
        }
    }

    // MARK: - 未完成区

    private var undoneSection: some View {
        Section {
            ForEach(model.undoneTasks) { task in
                row(task)
            }
            .onMove { source, destination in
                model.moveUndone(from: source, to: destination)
            }
            .onDelete { offsets in
                model.delete(at: offsets, in: model.undoneTasks)
            }

            if model.tasks.isEmpty {
                HStack {
                    Spacer()
                    VStack(spacing: 8) {
                        Image(systemName: "checklist")
                            .font(.system(size: 36))
                            .foregroundColor(.secondary)
                        Text("还没有今日任务")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        Text("点右上角 + 添加一个吧")
                            .font(.footnote)
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                }
                .padding(.vertical, 24)
            } else if model.undoneTasks.isEmpty {
                HStack {
                    Spacer()
                    Text("今日任务全部完成，休息一下 🎉")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    Spacer()
                }
                .padding(.vertical, 16)
            }
        } header: {
            Text("未完成 · \(model.undoneTasks.count)")
        }
    }

    // MARK: - 已完成区（可折叠）

    private var doneSection: some View {
        Section {
            if model.showDone {
                ForEach(model.doneTasks) { task in
                    row(task)
                }
                .onDelete { offsets in
                    model.delete(at: offsets, in: model.doneTasks)
                }
            }
        } header: {
            Button {
                withAnimation(.easeInOut(duration: 0.2)) {
                    model.showDone.toggle()
                }
            } label: {
                HStack(spacing: 4) {
                    Image(systemName: model.showDone ? "chevron.down" : "chevron.right")
                        .font(.caption2)
                    Text("已完成 · \(model.doneTasks.count)")
                }
                .font(.subheadline)
                .foregroundColor(.secondary)
            }
        }
    }

    // MARK: - 任务行

    private func row(_ task: DailyTask) -> some View {
        TaskRowView(task: task) {
            model.toggle(task)
        }
        .contentShape(Rectangle())
        .onTapGesture {
            model.editingTask = task
        }
        .swipeActions(edge: .leading, allowsFullSwipe: true) {
            Button {
                model.toggleStar(task)
            } label: {
                Label(task.isStarred ? "取消星标" : "星标", systemImage: "star.fill")
            }
            .tint(.yellow)
        }
    }
}

// MARK: - 任务行视图

struct TaskRowView: View {
    let task: DailyTask
    let onToggle: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            Button(action: onToggle) {
                ZStack {
                    Circle()
                        .stroke(
                            task.isDone ? Color.accentColor : Color.secondary.opacity(0.4),
                            lineWidth: 1.5
                        )
                        .frame(width: 24, height: 24)
                    if task.isDone {
                        Image(systemName: "checkmark")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(.accentColor)
                    }
                }
            }
            .buttonStyle(.plain)

            VStack(alignment: .leading, spacing: 3) {
                Text(task.title)
                    .strikethrough(task.isDone, color: .secondary)
                    .foregroundColor(task.isDone ? .secondary : .primary)
                if let note = task.note, !note.isEmpty {
                    Text(note)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
            }

            Spacer(minLength: 0)

            if task.isStarred && !task.isDone {
                Image(systemName: "star.fill")
                    .font(.caption)
                    .foregroundColor(.orange)
            }
        }
        .padding(.vertical, 2)
        .symbolEffect(.bounce, value: task.isDone)
    }
}

// MARK: - 今日头部卡片

struct TodayHeaderView: View {
    let done: Int
    let total: Int
    let streak: Int

    private var progress: Double {
        guard total > 0 else { return 0 }
        return min(1, Double(done) / Double(total))
    }

    private var headline: String {
        if total == 0 { return "规划一下今天要做什么" }
        if done == total { return "今日任务全部完成 🎉" }
        return "还剩 \(total - done) 项未完成"
    }

    var body: some View {
        let content = VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(Self.dateText)
                        .font(.subheadline)
                        .opacity(0.9)
                    Text(headline)
                        .font(.title3.bold())
                }
                Spacer()
                if streak > 0 {
                    HStack(spacing: 3) {
                        Image(systemName: "flame.fill")
                        Text("\(streak) 天")
                    }
                    .font(.subheadline.bold())
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(Capsule().fill(Color.white.opacity(0.22)))
                }
            }

            HStack(spacing: 10) {
                ProgressView(value: progress)
                    .progressViewStyle(.linear)
                    .tint(.white)
                Text("\(done)/\(total)")
                    .font(.system(.subheadline, design: .rounded).bold())
                    .monospacedDigit()
            }
        }
        .padding(16)
        .foregroundStyle(.white)

        Group {
            if #available(iOS 26.0, *) {
                // iOS 26：液态玻璃卡片，透出壁纸并带主题色调
                content
                    .glassEffect(
                        .regular.tint(Self.glassTint),
                        in: RoundedRectangle(cornerRadius: 24, style: .continuous)
                    )
            } else {
                // 旧系统：渐变卡片
                content
                    .background(
                        RoundedRectangle(cornerRadius: 20, style: .continuous)
                            .fill(Self.fallbackGradient)
                    )
            }
        }
        .listRowInsets(EdgeInsets())
    }

    private static let glassTint = Color(red: 1.00, green: 0.40, blue: 0.42)

    private static let fallbackGradient = LinearGradient(
        colors: [
            Color(red: 1.00, green: 0.55, blue: 0.38),
            Color(red: 0.96, green: 0.25, blue: 0.47),
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static var dateText: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "zh_CN")
        formatter.dateFormat = "M月d日 EEEE"
        return formatter.string(from: Date())
    }
}
