import Foundation
import SwiftUI
import UIKit
import WidgetKit

/// 主应用的视图模型：包装 TaskStore 并驱动界面刷新。
final class TaskViewModel: ObservableObject {
    @Published var tasks: [DailyTask] = []
    @Published var showQuickAdd = false
    @Published var editingTask: DailyTask?
    @Published var showDone = false

    let usesAppGroup: Bool

    private var quickAddObserver: NSObjectProtocol?

    var undoneTasks: [DailyTask] { tasks.filter { !$0.isDone } }
    var doneTasks: [DailyTask] { tasks.filter(\.isDone) }

    init() {
        usesAppGroup = TaskStore.shared.isUsingAppGroup
        reload()

        quickAddObserver = NotificationCenter.default.addObserver(
            forName: .quickAddRequested,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in
                self?.showQuickAdd = true
            }
        }
    }

    deinit {
        if let observer = quickAddObserver {
            NotificationCenter.default.removeObserver(observer)
        }
    }

    func reload() {
        tasks = TaskStore.shared.todayTasks()
    }

    /// 回到前台：消费快捷添加标记（冷启动兜底）并刷新列表
    func handleSceneActive() {
        if TaskStore.shared.consumeQuickAddFlag() {
            showQuickAdd = true
        }
        reload()
    }

    func toggle(_ task: DailyTask) {
        Haptics.light()
        TaskStore.shared.toggleTask(id: task.id)
        reload()
    }

    func toggleStar(_ task: DailyTask) {
        TaskStore.shared.toggleStar(id: task.id)
        reload()
    }

    func add(_ title: String, isStarred: Bool = false) {
        TaskStore.shared.addTask(title, isStarred: isStarred)
        reload()
    }

    func update(_ task: DailyTask) {
        TaskStore.shared.updateTask(task)
        reload()
    }

    func delete(_ task: DailyTask) {
        TaskStore.shared.deleteTask(id: task.id)
        reload()
    }

    func delete(at offsets: IndexSet, in section: [DailyTask]) {
        let ids = offsets.map { section[$0].id }
        for id in ids {
            TaskStore.shared.deleteTask(id: id)
        }
        reload()
    }

    /// 拖拽排序：未完成区内移动后，把整段展示顺序写回存储
    func moveUndone(from source: IndexSet, to destination: Int) {
        var undone = undoneTasks
        undone.move(fromOffsets: source, toOffset: destination)
        TaskStore.shared.reorderToday(undone + doneTasks)
        reload()
    }
}

/// 轻触觉反馈
enum Haptics {
    static func light() {
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }
}
