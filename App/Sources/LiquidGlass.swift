import SwiftUI

// Liquid Glass（iOS 26 液态玻璃）辅助：
// 真·glassEffect API 需要 iOS 26 SDK 编译 + iOS 26 运行时；
// 旧系统运行时自动回退到普通样式，工程最低部署版本保持 iOS 17。

extension View {
    /// iOS 26+ 应用带色调的 Liquid Glass；旧系统原样返回
    @ViewBuilder
    func liquidGlassTint(_ tint: Color, in shape: some Shape) -> some View {
        if #available(iOS 26.0, *) {
            glassEffect(.regular.tint(tint), in: shape)
        } else {
            self
        }
    }

    /// iOS 26+ 使用系统玻璃按钮样式；旧系统回退 plain
    @ViewBuilder
    func glassButtonIfAvailable() -> some View {
        if #available(iOS 26.0, *) {
            self.buttonStyle(.glass)
        } else {
            self.buttonStyle(.plain)
        }
    }
}
