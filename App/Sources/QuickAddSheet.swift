import SwiftUI

/// 快捷添加：从小组件 "+" 或应用内 "+" 弹出，自动聚焦键盘，回车即添加
struct QuickAddSheet: View {
    @EnvironmentObject private var model: TaskViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var title = ""
    @State private var isStarred = false
    @FocusState private var focused: Bool

    var body: some View {
        NavigationStack {
            VStack(spacing: 14) {
                HStack(spacing: 10) {
                    TextField("今天要做什么？", text: $title)
                        .focused($focused)
                        .font(.title3)
                        .padding(12)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color(.secondarySystemBackground))
                        )
                        .submitLabel(.done)
                        .onSubmit(addAndDismiss)

                    Button {
                        isStarred.toggle()
                    } label: {
                        Image(systemName: isStarred ? "star.circle.fill" : "star.circle")
                            .font(.title2)
                            .foregroundColor(isStarred ? .orange : .secondary)
                    }
                    .glassButtonIfAvailable()
                }
                .padding(.horizontal)

                Text("回车快速保存 · 点击列表中的任务可编辑详情")
                    .font(.caption)
                    .foregroundColor(.secondary)

                Spacer()
            }
            .padding(.top, 12)
            .navigationTitle("快捷添加")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("取消") { dismiss() }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("添加", action: addAndDismiss)
                        .bold()
                        .disabled(title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
            .onAppear {
                focused = true
            }
        }
    }

    private func addAndDismiss() {
        model.add(title, isStarred: isStarred)
        dismiss()
    }
}
