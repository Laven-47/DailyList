import SwiftUI

/// 编辑任务：点击列表行弹出，可改标题、备注、星标，或删除
struct EditTaskSheet: View {
    @EnvironmentObject private var model: TaskViewModel
    @Environment(\.dismiss) private var dismiss
    let task: DailyTask

    @State private var title: String
    @State private var note: String
    @State private var isStarred: Bool

    init(task: DailyTask) {
        self.task = task
        _title = State(initialValue: task.title)
        _note = State(initialValue: task.note ?? "")
        _isStarred = State(initialValue: task.isStarred)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("内容") {
                    TextField("任务标题", text: $title)
                    TextField("备注（可选）", text: $note, axis: .vertical)
                        .lineLimit(2...4)
                }

                Section {
                    Toggle(isOn: $isStarred) {
                        Label("星标（未完成区置顶）", systemImage: "star.fill")
                    }
                }

                Section {
                    Button(role: .destructive) {
                        model.delete(task)
                        dismiss()
                    } label: {
                        Label("删除任务", systemImage: "trash")
                    }
                }
            }
            .navigationTitle("编辑任务")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("取消") { dismiss() }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("保存", action: save)
                        .bold()
                        .disabled(title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
    }

    private func save() {
        var updated = task
        updated.title = title.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedNote = note.trimmingCharacters(in: .whitespacesAndNewlines)
        updated.note = trimmedNote.isEmpty ? nil : trimmedNote
        updated.isStarred = isStarred
        model.update(updated)
        dismiss()
    }
}
