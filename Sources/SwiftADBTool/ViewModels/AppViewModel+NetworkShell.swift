import AppKit
import Foundation
import SwiftUI

extension AppViewModel {
    func addForward() {
        guard let serial = validatedSerial() else { return }

        let local = forwardLocal.trimmingCharacters(in: .whitespacesAndNewlines)
        let remote = forwardRemote.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !local.isEmpty, !remote.isEmpty else {
            appendConsole("Forward 失败: 端口不能为空")
            return
        }

        runOperation("添加 Forward") { [adbPath] in
            let output = try await self.service.forward(local: local, remote: remote, serial: serial, adbPath: adbPath)
            return output.cleanedCommandOutput.isEmpty ? "Forward set: \(local) -> \(remote)" : output.cleanedCommandOutput
        }
    }

    func removeForward() {
        guard let serial = validatedSerial() else { return }

        let local = forwardLocal.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !local.isEmpty else {
            appendConsole("移除 Forward 失败: 本机端口为空")
            return
        }

        runOperation("移除 Forward") { [adbPath] in
            let output = try await self.service.removeForward(local: local, serial: serial, adbPath: adbPath)
            return output.cleanedCommandOutput.isEmpty ? "Forward removed: \(local)" : output.cleanedCommandOutput
        }
    }

    func refreshForwardRules() {
        guard let serial = validatedSerial() else { return }

        runOperation("刷新 Forward 列表") { [adbPath] in
            let rules = try await self.service.listForward(serial: serial, adbPath: adbPath)
            self.forwardRules = rules
            return "Forward 规则数: \(rules.count)"
        }
    }

    func addReverse() {
        guard let serial = validatedSerial() else { return }

        let remote = reverseRemote.trimmingCharacters(in: .whitespacesAndNewlines)
        let local = reverseLocal.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !remote.isEmpty, !local.isEmpty else {
            appendConsole("Reverse 失败: 端口不能为空")
            return
        }

        runOperation("添加 Reverse") { [adbPath] in
            let output = try await self.service.reverse(remote: remote, local: local, serial: serial, adbPath: adbPath)
            return output.cleanedCommandOutput.isEmpty ? "Reverse set: \(remote) -> \(local)" : output.cleanedCommandOutput
        }
    }

    func removeReverse() {
        guard let serial = validatedSerial() else { return }

        let remote = reverseRemote.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !remote.isEmpty else {
            appendConsole("移除 Reverse 失败: 设备端口为空")
            return
        }

        runOperation("移除 Reverse") { [adbPath] in
            let output = try await self.service.removeReverse(remote: remote, serial: serial, adbPath: adbPath)
            return output.cleanedCommandOutput.isEmpty ? "Reverse removed: \(remote)" : output.cleanedCommandOutput
        }
    }

    func refreshReverseRules() {
        guard let serial = validatedSerial() else { return }

        runOperation("刷新 Reverse 列表") { [adbPath] in
            let rules = try await self.service.listReverse(serial: serial, adbPath: adbPath)
            self.reverseRules = rules
            return "Reverse 规则数: \(rules.count)"
        }
    }

    func runShellCommand() {
        guard let serial = validatedSerial() else { return }

        let cmd = shellCommand.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cmd.isEmpty else {
            appendConsole("Shell 命令不能为空")
            return
        }

        runOperation("执行 Shell") { [adbPath] in
            let output = try await self.service.shell(command: cmd, serial: serial, adbPath: adbPath)
            self.shellOutput = output
            return "Shell 执行完成"
        }
    }

    func fetchLogcat() {
        guard let serial = validatedSerial() else { return }

        runOperation("获取 Logcat") { [adbPath] in
            let output = try await self.service.fetchLogcat(serial: serial, adbPath: adbPath)
            self.logcatOutput = output
            return "Logcat 获取完成"
        }
    }

    func clearLogcat() {
        guard let serial = validatedSerial() else { return }

        runOperation("清空 Logcat") { [adbPath] in
            _ = try await self.service.clearLogcat(serial: serial, adbPath: adbPath)
            self.logcatOutput = ""
            return "Logcat 已清空"
        }
    }
}
