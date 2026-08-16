# DailyList — 每日任务清单（iOS）

一个原生 iOS 任务清单应用，包含主应用 + 主屏幕小组件 + 锁屏小组件：

- **主应用**：渐变头部卡片（日期、进度、连续打卡 🔥）、未完成/已完成分区（已完成可折叠）、往日未完成任务自动顺延到今天
- **任务管理**：添加 / 切换完成 / 左滑删除、点击任务行编辑（标题、备注、星标）、星标置顶、左滑星标、编辑模式下拖拽排序
- **每日提醒**：设置中可开启本地通知提醒（默认 9:00，时间可调），免费签名可用
- **统计**：连续打卡天数、本周完成数、累计完成数 + 最近 7 天完成柱状图
- **主屏小组件**（小/中/大）：中/大尺寸逐行显示任务，每行圆形按钮**直接点按切换完成状态**，右上角 "+" **一键唤起快捷添加**；小尺寸显示进度环
- **锁屏小组件**（矩形/圆形/行内）：矩形显示前几条任务并可直接切换完成状态；圆形显示进度环；行内显示文字概要
- **小组件可配置**：长按组件 → 编辑组件，可开关"显示已完成任务"
- **iOS 26 液态玻璃（Liquid Glass）**：头部卡片、快捷添加按钮使用 `glassEffect` 玻璃材质并透出壁纸；主屏小组件改用毛玻璃底；导航栏/弹窗等系统控件随新系统自动玻璃化。iOS 17–25 运行时自动回退为渐变/纯色样式

技术栈：SwiftUI + WidgetKit + App Intents + Charts（最低 iOS 17，锁屏点按交互与液态玻璃需 iOS 26）。

> 注意：液态玻璃 API 必须用 Xcode 26（iOS 26 SDK）编译，因此构建流水线运行在 `macos-26` 服务器上。

**无需 Apple 开发者账号**：GitHub Actions 免费编译出未签名 IPA，本机用 Sideloadly + 免费 Apple ID 签名安装。

---

## 目录结构

```
DailyList/
├── project.yml                  # XcodeGen 工程定义（CI 上自动生成 .xcodeproj）
├── .github/workflows/build.yml  # GitHub Actions 编译流水线
├── Shared/                      # 主应用与小组件共用的代码
│   ├── TaskModel.swift          #   任务数据模型（星标/备注/完成时间/排序）+ App Group 常量
│   ├── TaskStore.swift          #   数据存取（读写/排序/星标/统计/提醒设置）
│   └── TaskIntents.swift        #   组件交互 Intent（切换完成 / 唤起快捷添加）
├── App/Sources/                 # 主应用
│   ├── ContentView.swift        #   主界面（头部卡片/分区折叠/滑动操作）
│   ├── QuickAddSheet.swift      #   快捷添加（支持星标）
│   ├── EditTaskSheet.swift      #   编辑任务（标题/备注/星标/删除）
│   ├── StatsView.swift          #   统计（连续打卡/周柱状图/累计）
│   ├── SettingsView.swift       #   设置（每日提醒/清空数据/诊断）
│   └── NotificationManager.swift#   本地每日提醒通知
├── App/Resources/               # 图标与颜色资源
├── Widget/Sources/              # 小组件（主屏 + 锁屏，支持配置隐藏已完成）
└── tools/gen_icon.ps1           # 图标生成脚本（可选）
```

---

## 第一步：把代码上传到 GitHub

> 仓库必须设为 **Public**（公开仓库的 macOS 编译服务器完全免费；本工程无任何隐私内容）。

### 方式 A：网页拖拽上传（推荐，无需 git，对不稳定网络最友好）

1. 登录 [github.com](https://github.com) → 右上角 **+** → **New repository**
2. 名称填 `DailyList`，选 **Public** → **Create repository**
3. 在新仓库页面点击 **uploading an existing file** 链接
4. 把本地 `DailyList` 文件夹里的 **App、Shared、Widget、tools 四个文件夹和 project.yml、README.md 两个文件** 拖进浏览器（网页上传会自动忽略隐藏文件，所以 `.github` 和 `.gitignore` 单独处理，见下一步）
5. 点 **Commit changes** 提交
6. 补上构建流水线文件：仓库页面点 **Add file → Create new file**，文件名输入 `.github/workflows/build.yml`（输入斜杠会自动建目录），把本地 `.github/workflows/build.yml` 的内容复制粘贴进去 → **Commit changes**

### 方式 B：git 命令行 + 代理（如果你有代理工具）

```bash
cd DailyList
git init
git add .
git commit -m "DailyList initial commit"
git branch -M main
git remote add origin https://github.com/你的用户名/DailyList.git

# 让 git 走本地代理（端口按你的代理软件改，Clash 默认 7890）
git config --global http.proxy http://127.0.0.1:7890
git config --global https.proxy http://127.0.0.1:7890

git push -u origin main
```

断连重试小技巧：`git push` 失败就再执行一次，git 会续传对象；仍失败可先 `git config --global http.postBuffer 524288000`。

### 方式 C：SSH 协议走 443 端口（无代理时往往更稳）

先在 GitHub → Settings → SSH keys 添加你的公钥，然后在 `~/.ssh/config` 写入：

```
Host github.com
  HostName ssh.github.com
  Port 443
  User git
```

之后用 SSH 地址推送：`git remote set-url origin git@github.com:你的用户名/DailyList.git`

---

## 第二步：GitHub Actions 云端编译（约 5 分钟）

1. 进入仓库的 **Actions** 标签页，首次使用点 **I understand my workflows, go ahead and enable them**
2. 上传代码后会**自动开始构建**；之后想重新出包，选左侧 **Build iOS App** → **Run workflow** → **Run workflow**
3. 等待构建完成（绿勾 ✓，约 5 分钟）
4. 点进这次运行记录，页面底部 **Artifacts** 区域下载 **DailyList-ipa**
5. 下载得到的是 zip 压缩包，**解压后**里面的 `DailyList.ipa` 才是安装包

> 构建失败（红叉）：点进运行记录看日志，把报错内容发给我即可修复。
> Artifacts 保留 14 天，过期后重新 Run workflow 即可再生成。

---

## 第三步：Windows 上签名并安装到 iPhone

### 一次性环境准备

1. 安装 **iTunes**（必须从 [apple.com.cn/itunes](https://www.apple.com.cn/itunes/) 下载，**不要**装 Microsoft Store 版）
2. 安装 **iCloud for Windows**（同样从苹果官网下载，不要 Store 版）
3. 从 [sideloadly.io](https://sideloadly.io/) 下载安装 **Sideloadly**

### 签名安装

1. 数据线连接 iPhone 和电脑，iPhone 弹窗点**信任**
2. 打开 Sideloadly，把 `DailyList.ipa` 拖入窗口
3. Apple ID 处填你的免费 Apple ID（邮箱+密码；开了两步验证会再要一个 6 位验证码）
4. （建议）点 **Advanced**（高级选项）：
   - 如果里面有 **App Groups** 相关输入项，填 `group.com.ls.dailylist.shared`——这决定小组件能否与主应用同步数据
   - 没有该项就保持默认
5. 点 **Start / 安装**，等待 iPhone 上出现应用图标

### iPhone 上首次信任

设置 → 通用 → **VPN与设备管理** → 开发者 App 下点你的 Apple ID → **信任**

> 担心 Apple ID 安全的话，可以注册一个专用小号来签名（需要能在 iPhone 上登录接收验证码）。

---

## 第四步：添加小组件

**先打开一次 DailyList 应用**（添加一两条任务），再添加小组件：

- **主屏幕**：长按桌面空白处 → 左上角 **+** → 搜索 `DailyList` → 选择尺寸添加
- **锁屏**：长按锁屏 → **自定** → 点日期下方的组件框 → 搜索 `DailyList` → 选矩形/圆形/行内样式

组件上直接点圆钮切换完成、点 "+" 添加任务（会打开应用弹出输入框）。

---

## 每周重签（免费证书 7 天有效）

免费 Apple ID 签名的应用**每 7 天过期**（图标变灰、无法打开）。续期方法：

1. 数据线连上电脑，打开 Sideloadly
2. 重复"签名安装"步骤（同一个 Apple ID、保持相同 Bundle ID）
3. 数据不会丢失，无需删除重装

建议每周固定一天（比如周日晚上）连电脑续签一次。另外注意：

- 免费 Apple ID 最多同时侧载 **3 个应用**
- 不影响本应用：任务清单不需要推送等付费能力

---

## 常见问题

| 现象 | 处理 |
|------|------|
| Generate Xcode project 步骤失败 | 多半是把整个 DailyList 外层文件夹拖进了浏览器（文件躺在了子目录里）。构建脚本已内置自动平移修正，更新 build.yml 重跑即可；也可删掉仓库重建，只上传文件夹里的内容 |
| Actions 构建红叉 | 点开运行记录复制报错日志发给我 |
| 报错找不到 `macos-26` 运行器 | 该镜像短暂不可用时等几小时重试；持续不可用则告诉我，我提供去玻璃版回退 |
| 下载的 artifact 打不开 | 先解压 zip，里面的 `.ipa` 才是安装包 |
| Sideloadly 报 App ID 相关错误 | 之前用该 Apple ID 签过太多应用，等几天或换小号；或在 Advanced 里改 Bundle ID |
| 桌面找不到小组件 | 先打开一次主应用；仍没有就重启 iPhone 再长按桌面添加 |
| 小组件显示的和主应用数据不一致 | App Group 未生效：确认 Sideloadly Advanced 里填了组名 `group.com.ls.dailylist.shared`；主应用列表顶部也会出现橙色提示 |
| 小组件一直显示示例数据 | 打开主应用改动一次任务（组件靠数据变化刷新），或等系统下一次自动刷新 |
| 应用 7 天后打不开 | 正常现象，按"每周重签"操作 |

---

## 二次开发说明

- 改完代码重新走第一~三步即可（git 方式 `git push`；网页方式在文件页点铅笔图标编辑粘贴）
- 工程文件 `.xcodeproj` 由 [XcodeGen](https://github.com/yonaskolb/XcodeGen) 从 `project.yml` 生成，CI 自动执行，本地无需安装
- 若将来买了付费开发者账号：用 Xcode 打开工程， Signing 里选你的 Team，App Group 能力勾上即可真机调试（工程里已内置 entitlements 定义）

## 隐私说明

所有任务数据仅保存在你手机本地的 App Group 容器中，无任何网络请求与上传。
