import AppKit
import Foundation
import SwiftUI

@MainActor
final class AppViewModel: ObservableObject {
    let service: ADBService
    let adbKeyboardInputMethodID = "com.android.adbkeyboard/.AdbIME"

    @Published var adbPath: String
    @Published var devices: [ADBDevice] = []
    @Published var selectedSerial: String = ""
    @Published var statusText: String = "就绪"
    @Published var isBusy = false

    @Published var connectionHost = "127.0.0.1:5555"
    @Published var tcpipPort = "5555"
    @Published var rebootMode: RebootMode = .system

    @Published var apkPath = ""
    @Published var installReplace = true
    @Published var uninstallPackage = ""
    @Published var uninstallKeepData = false
    @Published var launchPackage = ""
    @Published var launchActivity = ""
    @Published var packageFilter = ""
    @Published var packages: [String] = []

    @Published var pushLocalPath = ""
    @Published var pushRemotePath = "/sdcard/"
    @Published var pullRemotePath = "/sdcard/"
    @Published var pullLocalPath = ""
    @Published var screenRecordDuration = "15"

    @Published var localBrowserPath = FileManager.default.homeDirectoryForCurrentUser.path + "/"
    @Published var localPathEntries: [LocalPathEntry] = []
    @Published var selectedLocalEntryPath = ""

    @Published var remoteBrowserPath = "/sdcard/"
    @Published var remotePathEntries: [RemotePathEntry] = []
    @Published var selectedRemoteEntryPath = ""
    @Published private(set) var canGoRemoteBack = false
    @Published private(set) var canGoRemoteForward = false

    @Published var forwardLocal = "tcp:8080"
    @Published var forwardRemote = "tcp:8080"
    @Published var reverseRemote = "tcp:8080"
    @Published var reverseLocal = "tcp:8080"
    @Published var forwardRules: [String] = []
    @Published var reverseRules: [String] = []

    @Published var shellCommand = "getprop ro.product.model"
    @Published var shellOutput = ""
    @Published var logcatOutput = ""

    @Published var adbKeyboardAPKPath = ""
    @Published var adbKeyboardText = ""
    @Published var adbKeyboardUseBase64 = true
    @Published var adbKeyboardAutoSwitchIME = true
    @Published var adbKeyboardIMEList = ""
    @Published var inputMethodEntries: [InputMethodEntry] = []
    @Published var selectedInputMethodID = ""
    @Published var currentInputMethodID = ""
    @Published var adbKeyboardKeyCode = "67"
    @Published var adbKeyboardEditorCode = "2"
    @Published var adbKeyboardUnicodeCodes = ""
    @Published var adbKeyboardMetaCode = ""

    @Published var consoleOutput = ""

    var remoteBackHistory: [String] = []
    var remoteForwardHistory: [String] = []

    init(service: ADBService = ADBService()) {
        self.service = service
        self.adbPath = Self.detectADBPath()
    }

    static func detectADBPath() -> String {
        let env = ProcessInfo.processInfo.environment["ADB_PATH"]?.trimmingCharacters(in: .whitespacesAndNewlines)
        if let env, !env.isEmpty {
            return env
        }

        let candidates = [
            "/opt/homebrew/bin/adb",
            "/usr/local/bin/adb",
            "/usr/bin/adb"
        ]

        for path in candidates where FileManager.default.isExecutableFile(atPath: path) {
            return path
        }

        return "adb"
    }

    var selectedDevice: ADBDevice? {
        devices.first(where: { $0.serial == selectedSerial })
    }

    var filteredPackages: [String] {
        let keyword = packageFilter.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !keyword.isEmpty else { return packages }
        return packages.filter { $0.localizedCaseInsensitiveContains(keyword) }
    }

    func initialLoad() {
        refreshDevices()
        loadLocalPathEntriesIfNeeded()
    }

    func loadFileManagersIfNeeded() {
        loadRemotePathEntriesIfNeeded()
    }

    func loadLocalPathEntriesIfNeeded() {
        if localPathEntries.isEmpty {
            loadLocalPathEntries()
        }
    }

    func loadRemotePathEntriesIfNeeded() {
        if remotePathEntries.isEmpty {
            loadRemotePathEntries()
        }
    }
    func clearConsole() {
        consoleOutput = ""
    }

    func validatedSerial() -> String? {
        let serial = selectedSerial.trimmingCharacters(in: .whitespacesAndNewlines)
        if serial.isEmpty {
            appendConsole("未选择设备")
            statusText = "未选择设备"
            return nil
        }

        return serial
    }

    func updateRemoteHistoryState() {
        canGoRemoteBack = !remoteBackHistory.isEmpty
        canGoRemoteForward = !remoteForwardHistory.isEmpty
    }

    func normalizedRemoteDirectoryPath(_ path: String) -> String {
        var normalized = path.trimmingCharacters(in: .whitespacesAndNewlines)
        if normalized.isEmpty {
            return "/"
        }

        if !normalized.hasPrefix("/") {
            normalized = "/" + normalized
        }

        if normalized != "/" && !normalized.hasSuffix("/") {
            normalized += "/"
        }

        return normalized
    }

    func joinRemotePath(baseDirectory: String, name: String, isDirectory: Bool) -> String {
        let base = normalizedRemoteDirectoryPath(baseDirectory)
        let cleanName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        var path: String

        if base == "/" {
            path = "/" + cleanName
        } else {
            path = base + cleanName
        }

        if isDirectory && !path.hasSuffix("/") {
            path += "/"
        }

        return path
    }

    func normalizedLocalDirectoryPath(_ path: String) -> String {
        var rawPath = path.trimmingCharacters(in: .whitespacesAndNewlines)
        if rawPath.isEmpty {
            rawPath = FileManager.default.homeDirectoryForCurrentUser.path
        }

        var url = URL(fileURLWithPath: rawPath).standardizedFileURL
        var isDirectory = ObjCBool(false)
        if FileManager.default.fileExists(atPath: url.path, isDirectory: &isDirectory), !isDirectory.boolValue {
            url = url.deletingLastPathComponent()
        }

        var normalized = url.path
        if normalized.isEmpty {
            normalized = "/"
        }

        if normalized != "/" && !normalized.hasSuffix("/") {
            normalized += "/"
        }

        return normalized
    }

    func readLocalPathEntries(directoryPath: String) throws -> [LocalPathEntry] {
        let directoryURL = URL(fileURLWithPath: normalizedLocalDirectoryPath(directoryPath), isDirectory: true)
        let urls = try FileManager.default.contentsOfDirectory(
            at: directoryURL,
            includingPropertiesForKeys: [.isDirectoryKey],
            options: [.skipsHiddenFiles]
        )

        var entries: [LocalPathEntry] = urls.map { url in
            let values = try? url.resourceValues(forKeys: [.isDirectoryKey])
            let isDirectory = values?.isDirectory ?? false
            return LocalPathEntry(
                name: url.lastPathComponent,
                fullPath: url.path,
                isDirectory: isDirectory
            )
        }

        entries.sort { lhs, rhs in
            if lhs.isDirectory != rhs.isDirectory {
                return lhs.isDirectory
            }
            return lhs.name.localizedStandardCompare(rhs.name) == .orderedAscending
        }

        return entries
    }

    func appendConsole(_ line: String) {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss"
        let prefix = formatter.string(from: Date())

        if consoleOutput.isEmpty {
            consoleOutput = "[\(prefix)] \(line)"
        } else {
            consoleOutput += "\n[\(prefix)] \(line)"
        }
    }

    func runOperation(_ title: String, task: @escaping @MainActor () async throws -> String) {
        guard !isBusy else {
            appendConsole("当前正忙，已忽略: \(title)")
            return
        }

        isBusy = true
        statusText = "执行中: \(title)"
        appendConsole("执行中: \(title)")

        Task {
            do {
                let message = try await task()
                statusText = message
                appendConsole(message)
            } catch {
                let message = error.localizedDescription
                statusText = "错误: \(message)"
                appendConsole("错误: \(message)")
            }

            isBusy = false
        }
    }
}

extension String {
    var cleanedCommandOutput: String {
        trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
