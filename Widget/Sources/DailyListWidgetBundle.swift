import WidgetKit
import SwiftUI

/// 小组件扩展入口：主屏组件 + 锁屏组件
@main
struct DailyListWidgetBundle: WidgetBundle {
    var body: some Widget {
        TaskListWidget()
        LockScreenWidget()
    }
}
