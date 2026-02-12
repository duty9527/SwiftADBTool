import AppKit
import Foundation
import SwiftUI

extension AppViewModel {
    func refreshDevices() {
        runOperation("刷新设备") { [adbPath] in
            let found = try await self.service.listDevices(adbPath: adbPath)
            self.devices = found

            if let current = self.devices.first(where: { $0.serial == self.selectedSerial }) {
                self.selectedSerial = current.serial
            } else {
                self.selectedSerial = found.first?.serial ?? ""
            }

            return "已发现 \(found.count) 台设备"
        }
    }

    func connect() {
        let host = connectionHost.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !host.isEmpty else {
            appendConsole("连接失败: 地址为空")
            return
        }

        runOperation("连接设备") { [adbPath] in
            let output = try await self.service.connect(host: host, adbPath: adbPath)
            return output.cleanedCommandOutput
        }
    }

    func disconnectTarget() {
        let host = connectionHost.trimmingCharacters(in: .whitespacesAndNewlines)

        runOperation("断开连接") { [adbPath] in
            let output = try await self.service.disconnect(host: host, adbPath: adbPath)
            return output.cleanedCommandOutput
        }
    }

    func tcpip() {
        guard let serial = validatedSerial() else { return }

        let port = tcpipPort.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !port.isEmpty else {
            appendConsole("TCP/IP 端口不能为空")
            return
        }

        runOperation("切换 TCP/IP") { [adbPath] in
            let output = try await self.service.tcpip(port: port, serial: serial, adbPath: adbPath)
            return output.cleanedCommandOutput
        }
    }

    func rebootDevice() {
        guard let serial = validatedSerial() else { return }
        let mode = rebootMode

        runOperation("重启设备") { [adbPath] in
            let output = try await self.service.reboot(mode: mode, serial: serial, adbPath: adbPath)
            return output.cleanedCommandOutput.isEmpty ? "已发送重启命令" : output.cleanedCommandOutput
        }
    }

    func installAPK() {
        guard let serial = validatedSerial() else { return }

        let path = apkPath.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !path.isEmpty else {
            appendConsole("安装失败: APK 路径为空")
            return
        }

        let replace = installReplace

        runOperation("安装 APK") { [adbPath] in
            let output = try await self.service.install(
                apkPath: path,
                replace: replace,
                serial: serial,
                adbPath: adbPath
            )
            return output.cleanedCommandOutput
        }
    }

    func uninstallPackageNow() {
        guard let serial = validatedSerial() else { return }

        let pkg = uninstallPackage.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !pkg.isEmpty else {
            appendConsole("卸载失败: 包名为空")
            return
        }

        let keepData = uninstallKeepData

        runOperation("卸载应用") { [adbPath] in
            let output = try await self.service.uninstall(
                packageName: pkg,
                keepData: keepData,
                serial: serial,
                adbPath: adbPath
            )
            return output.cleanedCommandOutput
        }
    }

    func loadPackages() {
        guard let serial = validatedSerial() else { return }

        runOperation("加载包列表") { [adbPath] in
            let list = try await self.service.listPackages(serial: serial, adbPath: adbPath)
            self.packages = list
            return "已加载 \(list.count) 个包"
        }
    }

    func launchApp() {
        guard let serial = validatedSerial() else { return }

        let pkg = launchPackage.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !pkg.isEmpty else {
            appendConsole("启动失败: 包名为空")
            return
        }

        let activity = launchActivity.trimmingCharacters(in: .whitespacesAndNewlines)

        runOperation("启动应用") { [adbPath] in
            let output = try await self.service.launch(
                packageName: pkg,
                activity: activity.isEmpty ? nil : activity,
                serial: serial,
                adbPath: adbPath
            )
            return output.cleanedCommandOutput
        }
    }

    func stopApp() {
        guard let serial = validatedSerial() else { return }

        let pkg = launchPackage.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !pkg.isEmpty else {
            appendConsole("停止失败: 包名为空")
            return
        }

        runOperation("停止应用") { [adbPath] in
            let output = try await self.service.stop(packageName: pkg, serial: serial, adbPath: adbPath)
            return output.cleanedCommandOutput
        }
    }

    func pushFile() {
        guard let serial = validatedSerial() else { return }

        let local = pushLocalPath.trimmingCharacters(in: .whitespacesAndNewlines)
        let remote = pushRemotePath.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !local.isEmpty, !remote.isEmpty else {
            appendConsole("上传失败: 本地路径或设备路径为空")
            return
        }

        runOperation("上传文件") { [adbPath] in
            let output = try await self.service.push(localPath: local, remotePath: remote, serial: serial, adbPath: adbPath)
            return output.cleanedCommandOutput
        }
    }

    func pullFile() {
        guard let serial = validatedSerial() else { return }

        let remote = pullRemotePath.trimmingCharacters(in: .whitespacesAndNewlines)
        let local = pullLocalPath.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !remote.isEmpty, !local.isEmpty else {
            appendConsole("下载失败: 设备路径或本地目录为空")
            return
        }

        runOperation("下载文件") { [adbPath] in
            let output = try await self.service.pull(remotePath: remote, localPath: local, serial: serial, adbPath: adbPath)
            return output.cleanedCommandOutput
        }
    }

    func captureScreenshot(savePath: String) {
        guard let serial = validatedSerial() else { return }

        let target = savePath.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !target.isEmpty else {
            appendConsole("截图失败: 保存路径为空")
            return
        }

        runOperation("设备截图") { [adbPath] in
            try await self.service.screenshot(saveURL: URL(fileURLWithPath: target), serial: serial, adbPath: adbPath)
            return "截图已保存到 \(target)"
        }
    }

    func recordScreen(savePath: String) {
        guard let serial = validatedSerial() else { return }

        let target = savePath.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !target.isEmpty else {
            appendConsole("录屏失败: 保存路径为空")
            return
        }

        let duration = Int(screenRecordDuration.trimmingCharacters(in: .whitespacesAndNewlines)) ?? 15

        runOperation("录制屏幕") { [adbPath] in
            let output = try await self.service.screenRecord(
                saveURL: URL(fileURLWithPath: target),
                durationSeconds: duration,
                serial: serial,
                adbPath: adbPath
            )
            return output.cleanedCommandOutput
        }
    }
}
