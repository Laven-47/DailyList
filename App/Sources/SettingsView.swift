import SwiftUI

/// 设置：每日提醒（本地通知）、数据管理、诊断信息
struct SettingsView: View {
    @EnvironmentObject private var model: TaskViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var reminderOn = TaskStore.shared.reminderEnabled
    @State private var reminderTime = TaskStore.shared.reminderTime
    @State private var showClearConfirm = false

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Toggle("每日提醒", isOn: $reminderOn)
                        .onChange(of: reminderOn) { _, isOn in
                            handleReminderToggle(isOn)
                        }

                    if reminderOn {
                        DatePicker(
                            "提醒时间",
                            selection: $reminderTime,
                            displayedComponents: .hourAndMinute
                        )
                        .onChange(of: reminderTime) { _, newTime in
                            let components = Calendar.current.dateComponents([.hour, .minute], from: newTime)
                            NotificationManager.schedule(hour: components.hour ?? 9, minute: components.minute ?? 0)
                            TaskStore.shared.reminderTime = newTime
                        }
                    }
                } header: {
                    Text("通知")
                } footer: {
                    Text("每天固定时间提醒你查看今日任务。使用本地通知，无需网络，免费签名可用。")
                }

                if !TaskStore.shared.isUsingAppGroup {
                    Section {
                        Label(
                            "小组件数据共享未生效（App Group 不可用）。处理方法见 README 的 Sideloadly 设置说明。",
                            systemImage: "exclamationmark.triangle"
                        )
                        .font(.footnote)
                        .foregroundColor(.orange)
                    } header: {
                        Text("诊断")
                    }
                }

                Section {
                    Button(role: .destructive) {
                        showClearConfirm = true
                    } label: {
                        Label("清空全部任务数据", systemImage: "trash")
                    }
                    .confirmationDialog(
                        "确定清空全部任务？此操作不可恢复。",
                        isPresented: $showClearConfirm,
                        titleVisibility: .visible
                    ) {
                        Button("清空", role: .destructive) {
                            TaskStore.shared.clearAll()
                            model.reload()
                        }
                    }
                } header: {
                    Text("数据")
                } footer: {
                    Text("任务数据仅保存在本机，无任何网络上传。")
                }

                Section {
                    HStack {
                        Text("版本")
                        Spacer()
                        Text("1.1").foregroundColor(.secondary)
                    }
                }
            }
            .navigationTitle("设置")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("完成") { dismiss() }
                }
            }
        }
    }

    private func handleReminderToggle(_ isOn: Bool) {
        if isOn {
            let components = Calendar.current.dateComponents([.hour, .minute], from: reminderTime)
            let hour = components.hour ?? 9
            let minute = components.minute ?? 0
            TaskStore.shared.reminderTime = reminderTime
            Task { @MainActor in
                let success = await NotificationManager.enable(hour: hour, minute: minute)
                if !success {
                    reminderOn = false
                }
                TaskStore.shared.reminderEnabled = success
            }
        } else {
            NotificationManager.disable()
            TaskStore.shared.reminderEnabled = false
        }
    }
}
