# SwiftADBTool (macOS Apple Silicon)

A SwiftUI desktop tool for common Android Debug Bridge workflows on macOS (M-series).

## Implemented Features

- Device
  - List devices (`adb devices -l`)
  - Wireless connect / disconnect (`adb connect`, `adb disconnect`)
  - Switch to TCP/IP mode (`adb tcpip`)
  - Reboot modes (`reboot`, `reboot recovery`, `reboot bootloader`, `reboot sideload`)
- App Management
  - Install APK (`adb install`, `adb install -r`)
  - Uninstall package (`adb uninstall`, `adb uninstall -k`)
  - List packages (`pm list packages`)
  - Launch app (`am start` / `monkey`) and force-stop (`am force-stop`)
- File & Media
  - Push / Pull (`adb push`, `adb pull`)
  - Screenshot (`adb exec-out screencap -p`)
  - Screen record (`screenrecord` + pull)
- Network Mapping
  - Forward add/remove/list (`adb forward`)
  - Reverse add/remove/list (`adb reverse`)
- Debug
  - Run custom shell commands (`adb shell sh -c ...`)
  - Fetch/Clear logcat (`adb logcat -d`, `adb logcat -c`)
- Utility
  - Auto-detect `adb` path (`/opt/homebrew/bin/adb`, `/usr/local/bin/adb`, `/usr/bin/adb`, or `$ADB_PATH`)
  - Operation console with timestamps

## Requirements

1. macOS (Apple Silicon recommended)
2. Swift 6.2+
3. Android `adb` available

Install platform-tools (Homebrew):

```bash
brew install android-platform-tools
```

## Build and Run

```bash
swift build
swift run SwiftADBTool
```

If `adb` is not in `PATH`, set it in the UI `ADB Path` field or export env var:

```bash
export ADB_PATH=/opt/homebrew/bin/adb
```

## Packaging

Use the packaging script to produce a distributable macOS `.app` and `.zip`:

```bash
./scripts/package_macos_app.sh
```

Optional packaging metadata (environment variables):

- `APP_NAME` (default: `SwiftADBTool`)
- `EXECUTABLE_NAME` (default: `SwiftADBTool`)
- `BUNDLE_ID` (default: `com.swiftadbtool.app`)
- `APP_VERSION` (default: `1.0.0`)
- `BUILD_NUMBER` (default: `1`)
- `CONFIGURATION` (default: `release`)
- `OUT_DIR` (default: `./dist`)
- `SIGN_IDENTITY` (default empty; if set, script runs `codesign`)

Example:

```bash
APP_VERSION=1.0.0 BUILD_NUMBER=12 BUNDLE_ID=com.yourcompany.swiftadbtool \
SIGN_IDENTITY=\"Developer ID Application: Your Name (TEAMID)\" \
./scripts/package_macos_app.sh
```

## Project Layout

- `Package.swift`: Swift package config
- `Sources/SwiftADBTool/SwiftADBToolApp.swift`: app entry
- `Sources/SwiftADBTool/ContentView.swift`: main view
- `Sources/SwiftADBTool/Models/Models.swift`: shared models and errors
- `Sources/SwiftADBTool/Views/ContentView+*.swift`: view layer split by feature
- `Sources/SwiftADBTool/ViewModels/AppViewModel.swift`: view model core state/shared helpers
- `Sources/SwiftADBTool/ViewModels/AppViewModel+*.swift`: view model domain actions
- `Sources/SwiftADBTool/Services/ADBService.swift`: service core execution/path helpers
- `Sources/SwiftADBTool/Services/ADBService+*.swift`: service domain APIs
- `Sources/SwiftADBTool/Utilities/PanelHelper.swift`: macOS open/save panel helpers
- `Sources/SwiftADBTool/Utilities/Theme.swift`: theme/styles and reusable UI extensions
- `Sources/SwiftADBTool/Resources/`: reserved for assets/resources
- `Sources/SwiftADBTool/SupportingFiles/`: reserved for supporting files
- `Tests/UnitTests/`: reserved for unit tests
- `Tests/UITests/`: reserved for UI tests

## Notes

- This project focuses on high-frequency ADB capabilities used in development/testing.
- Some advanced/rare flags are not exposed as dedicated controls but can be executed via the Shell tab.

## Attribution

Note: This entire project was completed with Codex vibe code, with no code modifications, and submitted by the repository maintainer.
