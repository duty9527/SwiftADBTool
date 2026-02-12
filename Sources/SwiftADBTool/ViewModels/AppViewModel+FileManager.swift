import AppKit
import Foundation
import SwiftUI

extension AppViewModel {
    func loadLocalPathEntries() {
        let targetPath = normalizedLocalDirectoryPath(localBrowserPath)
        do {
            let entries = try readLocalPathEntries(directoryPath: targetPath)
            localBrowserPath = targetPath
            localPathEntries = entries
            selectedLocalEntryPath = targetPath
            let message = "已加载本地路径: \(targetPath)"
            statusText = message
            appendConsole(message)
        } catch {
            let message = "加载本地路径失败: \(error.localizedDescription)"
            statusText = "错误: \(message)"
            appendConsole(message)
        }
    }

    func selectLocalEntry(_ entry: LocalPathEntry) {
        selectedLocalEntryPath = entry.fullPath
    }

    func openLocalDirectory(_ entry: LocalPathEntry) {
        guard entry.isDirectory else {
            selectedLocalEntryPath = entry.fullPath
            return
        }

        localBrowserPath = normalizedLocalDirectoryPath(entry.fullPath)
        loadLocalPathEntries()
    }

    func goToLocalParentDirectory() {
        let current = URL(fileURLWithPath: normalizedLocalDirectoryPath(localBrowserPath), isDirectory: true).standardizedFileURL
        let parent = current.deletingLastPathComponent()
        let parentPath = normalizedLocalDirectoryPath(parent.path)

        if parentPath == normalizedLocalDirectoryPath(localBrowserPath) {
            return
        }

        localBrowserPath = parentPath
        loadLocalPathEntries()
    }

    func setLocalDirectoryRoot(_ path: String) {
        localBrowserPath = normalizedLocalDirectoryPath(path)
        loadLocalPathEntries()
    }

    func resetRemoteNavigation(to path: String? = nil) {
        remoteBackHistory.removeAll()
        remoteForwardHistory.removeAll()
        updateRemoteHistoryState()

        if let path {
            remoteBrowserPath = normalizedRemoteDirectoryPath(path)
        }
    }

    func loadRemotePathEntries() {
        guard let serial = validatedSerial() else { return }
        let targetPath = normalizedRemoteDirectoryPath(remoteBrowserPath)

        runOperation("加载设备路径") { [adbPath] in
            let entries = try await self.service.listRemotePathEntries(
                path: targetPath,
                serial: serial,
                adbPath: adbPath
            )

            self.remoteBrowserPath = targetPath
            self.remotePathEntries = entries
            self.selectedRemoteEntryPath = targetPath
            return "已加载设备路径: \(targetPath)"
        }
    }

    func jumpToRemoteDirectory(_ path: String, recordHistory: Bool = true) {
        let target = normalizedRemoteDirectoryPath(path)
        let current = normalizedRemoteDirectoryPath(remoteBrowserPath)

        if recordHistory && target != current {
            remoteBackHistory.append(current)
            remoteForwardHistory.removeAll()
            updateRemoteHistoryState()
        }

        remoteBrowserPath = target
        loadRemotePathEntries()
    }

    func openRemoteDirectory(_ entry: RemotePathEntry) {
        guard entry.isDirectory else {
            selectedRemoteEntryPath = entry.fullPath
            return
        }

        jumpToRemoteDirectory(entry.fullPath, recordHistory: true)
    }

    func selectRemoteEntry(_ entry: RemotePathEntry) {
        selectedRemoteEntryPath = entry.fullPath
    }

    func goToRemoteParentDirectory() {
        let current = normalizedRemoteDirectoryPath(remoteBrowserPath)
        if current == "/" {
            return
        }

        var trimmed = current
        if trimmed.hasSuffix("/") && trimmed.count > 1 {
            trimmed.removeLast()
        }

        let parent: String
        if let slashIndex = trimmed.lastIndex(of: "/") {
            if slashIndex == trimmed.startIndex {
                parent = "/"
            } else {
                parent = String(trimmed[..<slashIndex]) + "/"
            }
        } else {
            parent = "/"
        }

        jumpToRemoteDirectory(parent, recordHistory: true)
    }

    func goToPreviousRemotePath() {
        guard let previous = remoteBackHistory.popLast() else {
            return
        }

        let current = normalizedRemoteDirectoryPath(remoteBrowserPath)
        remoteForwardHistory.append(current)
        updateRemoteHistoryState()

        remoteBrowserPath = normalizedRemoteDirectoryPath(previous)
        loadRemotePathEntries()
    }

    func goToNextRemotePath() {
        guard let next = remoteForwardHistory.popLast() else {
            return
        }

        let current = normalizedRemoteDirectoryPath(remoteBrowserPath)
        remoteBackHistory.append(current)
        updateRemoteHistoryState()

        remoteBrowserPath = normalizedRemoteDirectoryPath(next)
        loadRemotePathEntries()
    }

    func uploadLocalItemsToCurrentRemoteDirectory(paths: [String], operationTitle: String = "上传到设备") {
        guard let serial = validatedSerial() else { return }

        let uniquePaths = Array(Set(paths.map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }))
            .filter { !$0.isEmpty }
            .sorted()
        guard !uniquePaths.isEmpty else { return }

        let remoteDirectory = normalizedRemoteDirectoryPath(remoteBrowserPath)
        pushRemotePath = remoteDirectory

        runOperation(operationTitle) { [adbPath] in
            for path in uniquePaths {
                _ = try await self.service.push(
                    localPath: path,
                    remotePath: remoteDirectory,
                    serial: serial,
                    adbPath: adbPath
                )
            }

            self.remotePathEntries = try await self.service.listRemotePathEntries(
                path: remoteDirectory,
                serial: serial,
                adbPath: adbPath
            )

            if uniquePaths.count == 1 {
                return "已上传到 \(remoteDirectory)"
            }
            return "已上传 \(uniquePaths.count) 项到 \(remoteDirectory)"
        }
    }

    func uploadDroppedLocalItems(paths: [String]) {
        uploadLocalItemsToCurrentRemoteDirectory(paths: paths, operationTitle: "拖拽上传")
    }

    func downloadRemoteEntry(_ entry: RemotePathEntry, toLocalDirectory localDirectory: String) {
        guard let serial = validatedSerial() else { return }

        let remoteSource = entry.fullPath
        let localTarget = normalizedLocalDirectoryPath(localDirectory)
        pullRemotePath = remoteSource
        pullLocalPath = localTarget

        runOperation("下载到本地") { [adbPath] in
            let output = try await self.service.pull(
                remotePath: remoteSource,
                localPath: localTarget,
                serial: serial,
                adbPath: adbPath
            )

            let clean = output.cleanedCommandOutput
            if clean.isEmpty {
                return "已下载到 \(localTarget)"
            }
            return clean
        }
    }

    func deleteRemoteEntry(_ entry: RemotePathEntry) {
        guard let serial = validatedSerial() else { return }

        let targetPath = entry.fullPath
        let currentDirectory = normalizedRemoteDirectoryPath(remoteBrowserPath)

        runOperation("删除设备文件") { [adbPath] in
            _ = try await self.service.deleteRemotePath(path: targetPath, serial: serial, adbPath: adbPath)
            self.remotePathEntries = try await self.service.listRemotePathEntries(
                path: currentDirectory,
                serial: serial,
                adbPath: adbPath
            )
            self.selectedRemoteEntryPath = currentDirectory
            return "已删除: \(entry.displayName)"
        }
    }

    func renameRemoteEntry(_ entry: RemotePathEntry, newName: String) {
        guard let serial = validatedSerial() else { return }

        let name = newName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !name.isEmpty else {
            appendConsole("重命名失败: 名称不能为空")
            return
        }

        guard !name.contains("/") else {
            appendConsole("重命名失败: 名称不能包含 /")
            return
        }

        if name == entry.name {
            appendConsole("重命名已取消: 名称未变化")
            return
        }

        let currentDirectory = normalizedRemoteDirectoryPath(remoteBrowserPath)
        let newPath = joinRemotePath(baseDirectory: currentDirectory, name: name, isDirectory: entry.isDirectory)

        runOperation("重命名设备文件") { [adbPath] in
            _ = try await self.service.renameRemotePath(
                from: entry.fullPath,
                to: newPath,
                serial: serial,
                adbPath: adbPath
            )

            self.remotePathEntries = try await self.service.listRemotePathEntries(
                path: currentDirectory,
                serial: serial,
                adbPath: adbPath
            )
            self.selectedRemoteEntryPath = newPath
            return "已重命名为: \(name)"
        }
    }

    func applyRemotePathToUpload() {
        let candidate = selectedRemoteEntryPath.trimmingCharacters(in: .whitespacesAndNewlines)
        let path = candidate.isEmpty ? normalizedRemoteDirectoryPath(remoteBrowserPath) : candidate
        pushRemotePath = path
        appendConsole("已设置上传目标路径: \(path)")
    }

    func applyRemotePathToDownload() {
        let candidate = selectedRemoteEntryPath.trimmingCharacters(in: .whitespacesAndNewlines)
        let path = candidate.isEmpty ? normalizedRemoteDirectoryPath(remoteBrowserPath) : candidate
        pullRemotePath = path
        appendConsole("已设置下载源路径: \(path)")
    }

    func uploadSelectedLocalToCurrentRemoteDirectory() {
        guard let serial = validatedSerial() else { return }

        let localSource = selectedLocalEntryPath.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !localSource.isEmpty else {
            appendConsole("上传失败: 请先选择本地文件或目录")
            return
        }

        let remoteDirectory = normalizedRemoteDirectoryPath(remoteBrowserPath)
        pushLocalPath = localSource
        pushRemotePath = remoteDirectory

        runOperation("上传到设备") { [adbPath] in
            let output = try await self.service.push(
                localPath: localSource,
                remotePath: remoteDirectory,
                serial: serial,
                adbPath: adbPath
            )

            self.remotePathEntries = try await self.service.listRemotePathEntries(
                path: remoteDirectory,
                serial: serial,
                adbPath: adbPath
            )

            let clean = output.cleanedCommandOutput
            if clean.isEmpty {
                return "已上传到 \(remoteDirectory)"
            }
            return clean
        }
    }

    func downloadSelectedRemoteToCurrentLocalDirectory() {
        guard let serial = validatedSerial() else { return }

        let remoteSource = selectedRemoteEntryPath.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !remoteSource.isEmpty else {
            appendConsole("下载失败: 请先选择设备端文件或目录")
            return
        }

        let localDirectory = normalizedLocalDirectoryPath(localBrowserPath)
        pullRemotePath = remoteSource
        pullLocalPath = localDirectory

        runOperation("下载到本地") { [adbPath] in
            let output = try await self.service.pull(
                remotePath: remoteSource,
                localPath: localDirectory,
                serial: serial,
                adbPath: adbPath
            )

            self.localPathEntries = try self.readLocalPathEntries(directoryPath: localDirectory)

            let clean = output.cleanedCommandOutput
            if clean.isEmpty {
                return "已下载到 \(localDirectory)"
            }
            return clean
        }
    }
}
