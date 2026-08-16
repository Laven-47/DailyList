import Charts
import SwiftUI

/// 统计：连续打卡、本周完成、累计完成 + 最近 7 天柱状图
struct StatsView: View {
    @Environment(\.dismiss) private var dismiss

    /// 图表数据点（Charts 的 key path 不支持元组，需要具名结构体）
    private struct DayCount: Identifiable {
        let date: Date
        let count: Int
        var id: Date { date }
    }

    private let weekData: [DayCount]
    private let streak: Int
    private let totalCompleted: Int

    init() {
        let store = TaskStore.shared
        weekData = store.dailyCompletionCounts(days: 7).map { DayCount(date: $0.date, count: $0.count) }
        streak = store.streakDays()
        totalCompleted = store.totalCompleted()
    }

    private var weekTotal: Int {
        weekData.reduce(0) { $0 + $1.count }
    }

    var body: some View {
        NavigationStack {
            List {
                Section("概览") {
                    HStack(spacing: 0) {
                        statCell(value: "\(streak)", label: "连续天数", icon: "flame.fill", color: .orange)
                        Divider().padding(.vertical, 8)
                        statCell(value: "\(weekTotal)", label: "本周完成", icon: "checkmark.circle.fill", color: .green)
                        Divider().padding(.vertical, 8)
                        statCell(value: "\(totalCompleted)", label: "累计完成", icon: "square.stack.3d.fill", color: .accentColor)
                    }
                    .padding(.vertical, 4)
                }

                Section("最近 7 天") {
                    Chart(weekData) { item in
                        BarMark(
                            x: .value("日期", item.date, unit: .day),
                            y: .value("完成数", item.count)
                        )
                        .foregroundStyle(Color.accentColor.gradient)
                        .cornerRadius(3)
                    }
                    .chartXAxis {
                        AxisMarks(values: .stride(by: .day)) { _ in
                            AxisValueLabel(format: .dateTime.weekday(.narrow))
                        }
                    }
                    .frame(height: 180)
                    .padding(.vertical, 8)

                    if weekTotal == 0 {
                        Text("完成一些任务后，这里会出现你的每日完成统计。")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }

                Section {
                    Text("统计基于任务的完成时间记录，数据保存在本机。")
                        .font(.footnote)
                        .foregroundColor(.secondary)
                }
            }
            .navigationTitle("统计")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("完成") { dismiss() }
                }
            }
        }
    }

    private func statCell(value: String, label: String, icon: String, color: Color) -> some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(color)
            Text(value)
                .font(.system(.title2, design: .rounded).bold())
            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}
