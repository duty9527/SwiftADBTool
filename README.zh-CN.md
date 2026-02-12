# SwiftADBTool (macOS Apple Silicon)

一个基于 SwiftUI 的桌面工具，用于在 macOS（M 系列）上处理常见的 Android Debug Bridge 工作流。

## 已实现功能

- 设备
  - 列出设备（`adb devices -l`）
  - 无线连接 / 断开连接（`adb connect`, `adb disconnect`）
  - 切换到 TCP/IP 模式（`adb tcpip`）
  - 重启模式（`reboot`, `reboot recovery`, `reboot bootloader`, `reboot sideload`）
- 应用管理
  - 安装 APK（`adb install`, `adb install -r`）
  - 卸载包（`adb uninstall`, `adb uninstall -k`）
  - 列出应用包（`pm list packages`）
  - 启动应用（`am start` / `monkey`）与强制停止（`am force-stop`）
- 文件与媒体
  - 推送 / 拉取（`adb push`, `adb pull`）
  - 截图（`adb exec-out screencap -p`）
  - 录屏（`screenrecord` + pull）
- 网络映射
  - Forward 添加/删除/列表（`adb forward`）
  - Reverse 添加/删除/列表（`adb reverse`）
- 调试
  - 执行自定义 shell 命令（`adb shell sh -c ...`）
  - 获取/清空 logcat（`adb logcat -d`, `adb logcat -c`）
- 工具能力
  - 自动检测 `adb` 路径（`/opt/homebrew/bin/adb`, `/usr/local/bin/adb`, `/usr/bin/adb`，或 `$ADB_PATH`）
  - 带时间戳的操作控制台

## 环境要求

1. macOS（推荐 Apple Silicon）
2. Swift 6.2+
3. 已安装可用的 Android `adb`

安装 platform-tools（Homebrew）：

```bash
brew install android-platform-tools
```

## 构建与运行

```bash
swift build
swift run SwiftADBTool
```

如果 `adb` 不在 `PATH` 中，可在 UI 的 `ADB Path` 字段中设置，或导出环境变量：

```bash
export ADB_PATH=/opt/homebrew/bin/adb
```

## 打包

使用打包脚本生成可分发的 macOS `.app` 和 `.zip`：

```bash
./scripts/package_macos_app.sh
```

可选打包元数据（环境变量）：

- `APP_NAME`（默认：`SwiftADBTool`）
- `EXECUTABLE_NAME`（默认：`SwiftADBTool`）
- `BUNDLE_ID`（默认：`com.swiftadbtool.app`）
- `APP_VERSION`（默认：`1.0.0`）
- `BUILD_NUMBER`（默认：`1`）
- `CONFIGURATION`（默认：`release`）
- `OUT_DIR`（默认：`./dist`）
- `SIGN_IDENTITY`（默认空；设置后脚本会运行 `codesign`）

示例：

```bash
APP_VERSION=1.0.0 BUILD_NUMBER=12 BUNDLE_ID=com.yourcompany.swiftadbtool \
SIGN_IDENTITY="Developer ID Application: Your Name (TEAMID)" \
./scripts/package_macos_app.sh
```

## 打包排障

如果打包后的应用无法启动或启动后立即退出，请使用最新打包脚本。它现在会：

- 将运行时资源复制到 `Contents/Resources`，避免缺失资源导致的启动崩溃
- 在未提供 `SIGN_IDENTITY` 时默认进行 ad-hoc 签名
- 首次构建因模块缓存/路径变化失败时，清理 `.build` 后自动重试一次

如果 macOS 在下载/解压后拦截应用（Gatekeeper），可移除 quarantine 属性：

```bash
xattr -dr com.apple.quarantine /path/to/SwiftADBTool.app
```

通常不需要 `sudo`。只有在提示 `Operation not permitted` 或 `Permission denied` 时，再使用：

```bash
sudo xattr -dr com.apple.quarantine /path/to/SwiftADBTool.app
```

## 项目结构

- `Package.swift`：Swift 包配置
- `Sources/SwiftADBTool/SwiftADBToolApp.swift`：应用入口
- `Sources/SwiftADBTool/ContentView.swift`：主视图
- `Sources/SwiftADBTool/Models/Models.swift`：共享模型与错误定义
- `Sources/SwiftADBTool/Views/ContentView+*.swift`：按功能拆分的视图层
- `Sources/SwiftADBTool/ViewModels/AppViewModel.swift`：视图模型核心状态/通用辅助
- `Sources/SwiftADBTool/ViewModels/AppViewModel+*.swift`：视图模型各领域动作
- `Sources/SwiftADBTool/Services/ADBService.swift`：服务层核心执行/路径辅助
- `Sources/SwiftADBTool/Services/ADBService+*.swift`：服务层各领域 API
- `Sources/SwiftADBTool/Utilities/PanelHelper.swift`：macOS 打开/保存面板辅助
- `Sources/SwiftADBTool/Utilities/Theme.swift`：主题/样式与可复用 UI 扩展
- `Sources/SwiftADBTool/Resources/`：资源目录预留
- `Sources/SwiftADBTool/SupportingFiles/`：支持文件目录预留
- `Tests/UnitTests/`：单元测试目录预留
- `Tests/UITests/`：UI 测试目录预留

## 说明

- 本项目聚焦于开发/测试中的高频 ADB 能力。
- 一些高级/低频参数没有做成独立控件，但可在 Shell 标签页中执行。

## 署名说明

附注：整个项目由 Codex Vibe coding 完成，未改动任何代码，由仓库维护者自行提交。
