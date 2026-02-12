import AppKit
import SwiftUI
import UniformTypeIdentifiers

extension ContentView {
    var filesTab: some View {
        GeometryReader { proxy in
            let middleHeight = max(proxy.size.height, 1)
            let sidePanelHeight = max((middleHeight - 12) / 2, 140)

            HStack(alignment: .top, spacing: 12) {
                panel("设备文件管理器", subtitle: "单窗口浏览设备目录；支持拖拽上传，右键下载、删除、重命名") {
                    VStack(alignment: .leading, spacing: 8) {
                        remoteFileToolbar

                        pathStrip(title: "当前设备路径", value: vm.remoteBrowserPath)

                        ZStack {
                            List {
                                if let parentPath = remoteParentPath {
                                    HStack(spacing: 8) {
                                        Image(systemName: "arrow.uturn.backward.circle.fill")
                                            .foregroundStyle(Theme.ocean)
                                            .frame(width: 16)
                                        Text("返回上级目录 (..)")
                                            .font(.mono(12.5))
                                            .foregroundStyle(Theme.ocean)
                                        Spacer()
                                    }
                                    .padding(.vertical, 2)
                                    .contentShape(Rectangle())
                                    .onTapGesture {
                                        vm.jumpToRemoteDirectory(parentPath)
                                    }
                                }

                                ForEach(vm.remotePathEntries, id: \.id) { entry in
                                    FileManagerEntryRow(
                                        name: entry.displayName,
                                        fullPath: entry.fullPath,
                                        isDirectory: entry.isDirectory,
                                        isSelected: vm.selectedRemoteEntryPath == entry.fullPath,
                                        folderTint: Theme.amber
                                    )
                                    .contentShape(Rectangle())
                                    .onTapGesture {
                                        vm.selectRemoteEntry(entry)
                                    }
                                    .onTapGesture(count: 2) {
                                        vm.openRemoteDirectory(entry)
                                    }
                                    .contextMenu {
                                        Button("下载到本地…") {
                                            vm.selectRemoteEntry(entry)
                                            downloadRemoteEntryWithDirectoryPicker(entry)
                                        }

                                        Button("重命名…") {
                                            vm.selectRemoteEntry(entry)
                                            beginRemoteRename(entry)
                                        }

                                        Divider()

                                        Button("删除", role: .destructive) {
                                            vm.selectRemoteEntry(entry)
                                            remoteDeleteTarget = entry
                                        }
                                    }
                                }
                            }
                            .listStyle(.inset)
                            .scrollContentBackground(.hidden)
                            .padding(6)
                            .background(
                                RoundedRectangle(cornerRadius: 12, style: .continuous)
                                    .fill(Theme.paper.opacity(0.88))
                                    .overlay {
                                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                                            .stroke(Theme.mist.opacity(0.95), lineWidth: 1)
                                    }
                            )
                            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                            .frame(maxHeight: .infinity)

                            if isRemoteDropTargeted {
                                RoundedRectangle(cornerRadius: 12, style: .continuous)
                                    .stroke(Theme.mint, style: StrokeStyle(lineWidth: 2, dash: [7]))
                                    .padding(6)
                                    .allowsHitTesting(false)
                            }
                        }
                        .onDrop(
                            of: [UTType.fileURL.identifier],
                            isTargeted: $isRemoteDropTargeted,
                            perform: handleRemoteFileDrop
                        )

                        Text("提示: 双击目录进入；拖拽 Finder 文件或文件夹到列表区域可直接上传。")
                            .font(.bodySans(12, weight: .medium))
                            .foregroundStyle(Theme.slate)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .topLeading)
                .frame(height: middleHeight, alignment: .top)

                VStack(spacing: 12) {
                    panel("截图", subtitle: "保存设备截图为 PNG") {
                        HStack {
                            Button("保存截图") {
                                if let path = PanelHelper.saveFile(defaultName: "screen.png", allowedExtensions: ["png"]) {
                                    vm.captureScreenshot(savePath: path)
                                }
                            }
                            .buttonStyle(.borderedProminent)
                            .tint(Theme.ocean)

                            Spacer()
                        }
                    }
                    .frame(height: sidePanelHeight, alignment: .topLeading)

                    panel("录屏", subtitle: "录制并保存为 MP4") {
                        VStack(spacing: 10) {
                            HStack {
                                labelTag("录制时长")
                                TextField("15", text: $vm.screenRecordDuration)
                                    .textFieldStyle(.roundedBorder)
                                    .frame(width: 80)
                                Text("秒 (1-180)")
                                    .font(.bodySans(12, weight: .medium))
                                    .foregroundStyle(Theme.slate)
                                Spacer()
                            }

                            HStack {
                                Button("开始录屏") {
                                    if let path = PanelHelper.saveFile(defaultName: "record.mp4", allowedExtensions: ["mp4"]) {
                                        vm.recordScreen(savePath: path)
                                    }
                                }
                                .buttonStyle(.borderedProminent)
                                .tint(Theme.coral)
                                Spacer()
                            }
                        }
                    }
                    .frame(height: sidePanelHeight, alignment: .topLeading)
                }
                .frame(width: 360, height: middleHeight, alignment: .top)
            }
            .frame(width: proxy.size.width, height: middleHeight, alignment: .topLeading)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .sheet(item: $remoteRenameTarget) { entry in
            remoteRenameSheet(entry)
        }
        .alert("确认删除", isPresented: remoteDeleteAlertBinding) {
            Button("取消", role: .cancel) {
                remoteDeleteTarget = nil
            }
            Button("删除", role: .destructive) {
                if let entry = remoteDeleteTarget {
                    vm.deleteRemoteEntry(entry)
                }
                remoteDeleteTarget = nil
            }
        } message: {
            Text(remoteDeleteMessage)
        }
    }

    var remoteFileToolbar: some View {
        HStack(spacing: 8) {
            Text("设备目录")
                .font(.bodySans(13, weight: .bold))
                .foregroundStyle(Theme.ink)

            Button {
                vm.goToPreviousRemotePath()
            } label: {
                Label("后退", systemImage: "chevron.left")
            }
            .buttonStyle(.bordered)
            .disabled(!vm.canGoRemoteBack)

            Button {
                vm.goToNextRemotePath()
            } label: {
                Label("前进", systemImage: "chevron.right")
            }
            .buttonStyle(.bordered)
            .disabled(!vm.canGoRemoteForward)

            Button("上一级") {
                vm.goToRemoteParentDirectory()
            }
            .buttonStyle(.bordered)

            Spacer()

            Button("刷新") {
                vm.loadRemotePathEntries()
            }
            .buttonStyle(.bordered)

            Menu("快捷路径") {
                ForEach(remoteShortcutDirectories, id: \.self) { path in
                    Button(path) {
                        vm.jumpToRemoteDirectory(path)
                    }
                }
            }

            Button("上传文件或目录…") {
                let paths = PanelHelper.chooseFilesAndDirectories()
                vm.uploadLocalItemsToCurrentRemoteDirectory(paths: paths)
            }
            .buttonStyle(.borderedProminent)
            .tint(Theme.mint)
        }
    }

    var remoteParentPath: String? {
        let current = vm.remoteBrowserPath.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !current.isEmpty, current != "/" else {
            return nil
        }

        var trimmed = current
        if trimmed.hasSuffix("/") && trimmed.count > 1 {
            trimmed.removeLast()
        }

        guard let slashIndex = trimmed.lastIndex(of: "/") else {
            return "/"
        }

        if slashIndex == trimmed.startIndex {
            return "/"
        }

        return String(trimmed[..<slashIndex]) + "/"
    }

    var remoteShortcutDirectories: [String] {
        [
            "/",
            "/sdcard/",
            "/storage/emulated/0/",
            "/data/local/tmp/",
            "/sdcard/Download/"
        ]
    }

    var remoteDeleteAlertBinding: Binding<Bool> {
        Binding(
            get: { remoteDeleteTarget != nil },
            set: { isPresented in
                if !isPresented {
                    remoteDeleteTarget = nil
                }
            }
        )
    }

    var remoteDeleteMessage: String {
        if let target = remoteDeleteTarget {
            return "将永久删除 \(target.displayName)，该操作不可撤销。"
        }
        return "该操作不可撤销。"
    }

    func beginRemoteRename(_ entry: RemotePathEntry) {
        remoteRenameText = entry.name
        remoteRenameTarget = entry
    }

    func downloadRemoteEntryWithDirectoryPicker(_ entry: RemotePathEntry) {
        if let localDirectory = PanelHelper.chooseDirectory() {
            vm.downloadRemoteEntry(entry, toLocalDirectory: localDirectory)
        }
    }

    func remoteRenameSheet(_ entry: RemotePathEntry) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("重命名")
                .font(.display(18, weight: .bold))
                .foregroundStyle(Theme.ink)

            Text("当前项目: \(entry.displayName)")
                .font(.bodySans(12, weight: .medium))
                .foregroundStyle(Theme.slate)

            TextField("输入新名称", text: $remoteRenameText)
                .textFieldStyle(.roundedBorder)

            HStack {
                Spacer()

                Button("取消") {
                    remoteRenameTarget = nil
                }
                .keyboardShortcut(.cancelAction)

                Button("保存") {
                    vm.renameRemoteEntry(entry, newName: remoteRenameText)
                    remoteRenameTarget = nil
                }
                .buttonStyle(.borderedProminent)
                .tint(Theme.ocean)
                .keyboardShortcut(.defaultAction)
                .disabled(remoteRenameText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
        }
        .padding(18)
        .frame(width: 420)
    }

    func pathStrip(title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title)
                .font(.bodySans(11, weight: .semibold))
                .foregroundStyle(Theme.slate)
            Text(value)
                .font(.mono(11.5))
                .lineLimit(1)
                .foregroundStyle(Theme.ink)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 8)
                .padding(.vertical, 6)
                .background(
                    RoundedRectangle(cornerRadius: 7, style: .continuous)
                        .fill(Color.white.opacity(0.72))
                )
        }
    }

    func handleRemoteFileDrop(providers: [NSItemProvider]) -> Bool {
        let fileProviders = providers.filter {
            $0.hasItemConformingToTypeIdentifier(UTType.fileURL.identifier)
        }
        guard !fileProviders.isEmpty else {
            return false
        }

        let pathStore = ThreadSafePathStore()
        let group = DispatchGroup()

        for provider in fileProviders {
            group.enter()
            provider.loadItem(forTypeIdentifier: UTType.fileURL.identifier, options: nil) { item, _ in
                defer { group.leave() }
                guard let url = FileDropTextField.decodeDroppedURL(item: item) else {
                    return
                }

                let path = url.standardizedFileURL.path
                guard !path.isEmpty, FileManager.default.fileExists(atPath: path) else {
                    return
                }

                pathStore.append(path)
            }
        }

        DispatchQueue.global(qos: .userInitiated).async {
            group.wait()
            let unique = Array(Set(pathStore.values())).sorted()
            guard !unique.isEmpty else {
                return
            }

            DispatchQueue.main.async {
                vm.uploadDroppedLocalItems(paths: unique)
            }
        }

        return true
    }
}
