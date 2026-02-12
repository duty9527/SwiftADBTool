import AppKit
import Foundation
import SwiftUI

extension AppViewModel {
    func installADBKeyboardAPK() {
        guard let serial = validatedSerial() else { return }

        let path = adbKeyboardAPKPath.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !path.isEmpty else {
            appendConsole("安装 ADBKeyBoard 失败: 请先选择 APK 文件")
            return
        }

        guard FileManager.default.fileExists(atPath: path) else {
            appendConsole("安装 ADBKeyBoard 失败: 文件不存在")
            return
        }

        runOperation("安装 ADBKeyBoard") { [adbPath] in
            let output = try await self.service.install(
                apkPath: path,
                replace: true,
                serial: serial,
                adbPath: adbPath
            )
            let clean = output.cleanedCommandOutput
            if clean.isEmpty {
                return "ADBKeyBoard 安装命令已发送"
            }
            return clean
        }
    }

    func enableADBKeyboardInputMethod() {
        guard let serial = validatedSerial() else { return }
        let imeID = adbKeyboardInputMethodID

        runOperation("启用 ADBKeyBoard 输入法") { [adbPath] in
            let output = try await self.service.enableInputMethod(
                imeID,
                serial: serial,
                adbPath: adbPath
            )
            let clean = output.cleanedCommandOutput
            if clean.isEmpty {
                let (entries, current) = try await self.fetchInputMethodEntries(serial: serial, adbPath: adbPath)
                self.applyInputMethodEntries(entries, currentID: current)
                return "已启用输入法: \(imeID)"
            }
            let (entries, current) = try await self.fetchInputMethodEntries(serial: serial, adbPath: adbPath)
            self.applyInputMethodEntries(entries, currentID: current)
            return clean
        }
    }

    func switchToADBKeyboardInputMethod() {
        selectedInputMethodID = adbKeyboardInputMethodID
        switchToSelectedInputMethod(title: "切换输入法到 ADBKeyBoard")
    }

    func switchToSelectedInputMethod(title: String = "切换输入法") {
        guard let serial = validatedSerial() else { return }

        let imeID = selectedInputMethodID.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !imeID.isEmpty else {
            appendConsole("切换输入法失败: 请先选择一个输入法")
            return
        }

        runOperation(title) { [adbPath] in
            _ = try? await self.service.enableInputMethod(
                imeID,
                serial: serial,
                adbPath: adbPath
            )
            let output = try await self.service.setInputMethod(
                imeID,
                serial: serial,
                adbPath: adbPath
            )
            try await Task.sleep(nanoseconds: 260_000_000)
            let (entries, current) = try await self.fetchInputMethodEntries(serial: serial, adbPath: adbPath)
            self.applyInputMethodEntries(entries, currentID: current)

            let clean = output.cleanedCommandOutput
            if clean.isEmpty {
                if current == imeID {
                    return "已切换输入法: \(imeID)"
                }
                return "已发送切换命令: \(imeID) (当前: \(current))"
            }
            return clean
        }
    }

    func resetInputMethodToDefault() {
        guard let serial = validatedSerial() else { return }

        runOperation("重置输入法") { [adbPath] in
            let output = try await self.service.resetInputMethod(serial: serial, adbPath: adbPath)
            try await Task.sleep(nanoseconds: 260_000_000)
            let (entries, current) = try await self.fetchInputMethodEntries(serial: serial, adbPath: adbPath)
            self.applyInputMethodEntries(entries, currentID: current)
            let clean = output.cleanedCommandOutput
            if clean.isEmpty {
                return "已重置输入法为默认"
            }
            return clean
        }
    }

    func loadInputMethodList() {
        guard let serial = validatedSerial() else { return }

        runOperation("读取输入法列表") { [adbPath] in
            let (entries, current) = try await self.fetchInputMethodEntries(serial: serial, adbPath: adbPath)
            self.applyInputMethodEntries(entries, currentID: current)

            if entries.isEmpty {
                return "未读取到输入法"
            }
            return "已读取 \(entries.count) 个输入法"
        }
    }

    func fillADBKeyboardTextFromClipboard() {
        let pasteboard = NSPasteboard.general
        guard let content = pasteboard.string(forType: .string) else {
            appendConsole("剪贴板没有可用文本")
            return
        }

        let text = content.trimmingCharacters(in: .newlines)
        guard !text.isEmpty else {
            appendConsole("剪贴板没有可用文本")
            return
        }

        adbKeyboardText = text
        appendConsole("已从剪贴板填充文本 (\(text.count) 字符)")
    }

    func sendADBKeyboardText() {
        guard let serial = validatedSerial() else { return }

        let text = adbKeyboardText
        guard !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            appendConsole("发送失败: 文本内容为空")
            return
        }

        let useBase64 = adbKeyboardUseBase64
        let autoSwitchIME = adbKeyboardAutoSwitchIME
        let imeID = adbKeyboardInputMethodID

        runOperation("发送 ADBKeyBoard 文本") { [adbPath] in
            if autoSwitchIME {
                _ = try? await self.service.enableInputMethod(
                    imeID,
                    serial: serial,
                    adbPath: adbPath
                )
                _ = try await self.service.setInputMethod(
                    imeID,
                    serial: serial,
                    adbPath: adbPath
                )
                try await Task.sleep(nanoseconds: 320_000_000)
            }

            let output: String
            if useBase64 {
                output = try await self.service.sendADBKeyboardTextBase64(
                    text,
                    serial: serial,
                    adbPath: adbPath
                )
            } else {
                output = try await self.service.sendADBKeyboardText(
                    text,
                    serial: serial,
                    adbPath: adbPath
                )
            }

            let clean = output.cleanedCommandOutput
            let modeText = useBase64 ? "Base64" : "普通文本"
            if clean.isEmpty {
                return "已发送文本 (\(modeText))"
            }
            return "已发送文本 (\(modeText))\n\(clean)"
        }
    }

    private func fetchInputMethodEntries(serial: String, adbPath: String) async throws -> ([InputMethodEntry], String) {
        let allIDs = try await service.listInputMethodIDs(all: true, serial: serial, adbPath: adbPath)
        let enabledIDs = Set(try await service.listInputMethodIDs(all: false, serial: serial, adbPath: adbPath))
        let currentID = try await service.currentInputMethod(serial: serial, adbPath: adbPath)

        var orderedIDs: [String] = []
        var seen: Set<String> = []

        func appendUnique(_ id: String) {
            let value = id.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !value.isEmpty else { return }
            if seen.insert(value).inserted {
                orderedIDs.append(value)
            }
        }

        for id in allIDs {
            appendUnique(id)
        }
        for id in enabledIDs {
            appendUnique(id)
        }
        appendUnique(currentID)

        let entries = orderedIDs.map { id in
            InputMethodEntry(
                id: id,
                isEnabled: enabledIDs.contains(id),
                isCurrent: id == currentID
            )
        }

        return (entries, currentID)
    }

    private func applyInputMethodEntries(_ entries: [InputMethodEntry], currentID: String) {
        inputMethodEntries = entries
        currentInputMethodID = currentID

        let selected = selectedInputMethodID.trimmingCharacters(in: .whitespacesAndNewlines)
        if selected.isEmpty || !entries.contains(where: { $0.id == selected }) {
            if !currentID.isEmpty {
                selectedInputMethodID = currentID
            } else {
                selectedInputMethodID = entries.first?.id ?? ""
            }
        }

        adbKeyboardIMEList = entries
            .map { entry in
                let state: String
                if entry.isCurrent {
                    state = "当前"
                } else if entry.isEnabled {
                    state = "已启用"
                } else {
                    state = "未启用"
                }
                return "\(entry.id) [\(state)]"
            }
            .joined(separator: "\n")
    }

    func clearADBKeyboardTextOnDevice() {
        guard let serial = validatedSerial() else { return }

        runOperation("清空设备输入框") { [adbPath] in
            let output = try await self.service.clearADBKeyboardText(serial: serial, adbPath: adbPath)
            let clean = output.cleanedCommandOutput
            if clean.isEmpty {
                return "已发送清空输入框命令"
            }
            return clean
        }
    }

    func sendADBKeyboardKeyEvent() {
        guard let serial = validatedSerial() else { return }

        let code = Int(adbKeyboardKeyCode.trimmingCharacters(in: .whitespacesAndNewlines))
        guard let code, code >= 0 else {
            appendConsole("发送按键失败: keyevent 必须是非负整数")
            return
        }

        runOperation("发送按键事件") { [adbPath] in
            let systemKeyCodes: Set<Int> = [3, 4, 82, 111, 187]
            let output: String
            if systemKeyCodes.contains(code) {
                output = try await self.service.sendShellKeyEvent(
                    code: code,
                    serial: serial,
                    adbPath: adbPath
                )
            } else {
                output = try await self.service.sendADBKeyboardKeyEvent(
                    code: code,
                    serial: serial,
                    adbPath: adbPath
                )
            }
            let clean = output.cleanedCommandOutput
            if clean.isEmpty {
                return "已发送 keyevent: \(code)"
            }
            return clean
        }
    }

    func sendQuickSystemKeyEvent(code: Int, label: String) {
        guard let serial = validatedSerial() else { return }
        guard code >= 0 else {
            appendConsole("发送快捷按键失败: keyevent 必须是非负整数")
            return
        }

        runOperation("发送快捷按键") { [adbPath] in
            let output = try await self.service.sendShellKeyEvent(
                code: code,
                serial: serial,
                adbPath: adbPath
            )
            let clean = output.cleanedCommandOutput
            if clean.isEmpty {
                return "已发送快捷按键: \(label) (\(code))"
            }
            return clean
        }
    }

    func sendADBKeyboardEditorAction() {
        guard let serial = validatedSerial() else { return }

        let code = Int(adbKeyboardEditorCode.trimmingCharacters(in: .whitespacesAndNewlines))
        guard let code, code >= 0 else {
            appendConsole("发送编辑动作失败: action code 必须是非负整数")
            return
        }

        runOperation("发送编辑动作") { [adbPath] in
            let output = try await self.service.sendADBKeyboardEditorAction(
                code: code,
                serial: serial,
                adbPath: adbPath
            )
            let clean = output.cleanedCommandOutput
            if clean.isEmpty {
                return "已发送 editor action: \(code)"
            }
            return clean
        }
    }

    func sendADBKeyboardUnicodeCodes() {
        guard let serial = validatedSerial() else { return }

        let codes = adbKeyboardUnicodeCodes.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !codes.isEmpty else {
            appendConsole("发送 Unicode 失败: 编码列表为空")
            return
        }

        runOperation("发送 Unicode 字符编码") { [adbPath] in
            let output = try await self.service.sendADBKeyboardUnicodeCodes(
                codesCSV: codes,
                serial: serial,
                adbPath: adbPath
            )
            let clean = output.cleanedCommandOutput
            if clean.isEmpty {
                return "已发送 Unicode 编码序列"
            }
            return clean
        }
    }

    func sendADBKeyboardMetaCode() {
        guard let serial = validatedSerial() else { return }

        let code = adbKeyboardMetaCode.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !code.isEmpty else {
            appendConsole("发送组合键失败: mcode 为空")
            return
        }

        runOperation("发送组合键") { [adbPath] in
            let output = try await self.service.sendADBKeyboardMetaCode(
                code,
                serial: serial,
                adbPath: adbPath
            )
            let clean = output.cleanedCommandOutput
            if clean.isEmpty {
                return "已发送 mcode: \(code)"
            }
            return clean
        }
    }
}
