import SwiftUI

@main
struct DailyListApp: App {
    @StateObject private var model = TaskViewModel()
    @Environment(\.scenePhase) private var scenePhase

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(model)
                .onOpenURL { url in
                    // 兜底路径：不支持按钮交互的场景里，组件整体点按通过 URL 打开应用
                    if url.absoluteString.contains("quickadd") {
                        model.showQuickAdd = true
                    }
                }
                .onChange(of: scenePhase) { _, phase in
                    if phase == .active {
                        model.handleSceneActive()
                    }
                }
        }
    }
}
