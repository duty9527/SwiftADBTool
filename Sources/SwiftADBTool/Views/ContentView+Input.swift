import SwiftUI

extension ContentView {
    var inputTab: some View {
        GeometryReader { proxy in
            let middleHeight = max(proxy.size.height, 1)
            let panelSpacing: CGFloat = 12
            let sidePanelHeight = max((middleHeight - panelSpacing) / 2, 140)
            let textSendControlColumnWidth: CGFloat = 188
            let commandDropdownWidth: CGFloat = 100
            let commandListButtonWidth: CGFloat = 86
            let commandSendButtonWidth: CGFloat = 128
            let textSendEditorFill = Color(red: 0.92, green: 0.95, blue: 0.99)

            HStack(alignment: .top, spacing: 12) {
                VStack(spacing: panelSpacing) {
                    panel("输入法配置", subtitle: "安装 ADBKeyBoard，读取并切换输入法") {
                        VStack(alignment: .leading, spacing: 6) {
                            HStack(spacing: 8) {
                                FileDropTextField(
                                    placeholder: "拖拽 adb_keyboard.apk 到这里",
                                    text: $vm.adbKeyboardAPKPath,
                                    allowedExtensions: ["apk"],
                                    allowDirectory: false
                                )

                                Button("选择 APK") {
                                    if let path = PanelHelper.chooseFile(allowedExtensions: ["apk"]) {
                                        vm.adbKeyboardAPKPath = path
                                    }
                                }
                                .buttonStyle(.bordered)

                                Button("安装") {
                                    vm.installADBKeyboardAPK()
                                }
                                .buttonStyle(.borderedProminent)
                                .tint(Theme.mint)
                            }

                            HStack(spacing: 8) {
                                Button("读取输入法列表") {
                                    vm.loadInputMethodList()
                                }
                                .buttonStyle(.borderedProminent)
                                .tint(Theme.ocean)

                                Button("启用 ADBKeyBoard") {
                                    vm.enableADBKeyboardInputMethod()
                                }
                                .buttonStyle(.bordered)

                                Button("切换到 ADBKeyBoard") {
                                    vm.switchToADBKeyboardInputMethod()
                                }
                                .buttonStyle(.bordered)

                                Button("重置输入法") {
                                    vm.resetInputMethodToDefault()
                                }
                                .buttonStyle(.bordered)

                                Spacer()
                            }

                            HStack(spacing: 8) {
                                labelTag("当前输入法")
                                Text(vm.currentInputMethodID.isEmpty ? "-" : vm.currentInputMethodID)
                                    .font(.mono(11.5))
                                    .foregroundStyle(Theme.ink)
                                    .lineLimit(1)
                                Spacer()
                            }

                            HStack(spacing: 8) {
                                Picker("可用输入法", selection: $vm.selectedInputMethodID) {
                                    if vm.inputMethodEntries.isEmpty {
                                        Text("请先读取输入法列表").tag("")
                                    } else {
                                        ForEach(vm.inputMethodEntries) { entry in
                                            Text(entry.displayName).tag(entry.id)
                                        }
                                    }
                                }
                                .labelsHidden()
                                .pickerStyle(.menu)
                                .frame(maxWidth: .infinity)

                                Button("切换到所选输入法") {
                                    vm.switchToSelectedInputMethod()
                                }
                                .buttonStyle(.borderedProminent)
                                .tint(Theme.mint)
                                .disabled(vm.selectedInputMethodID.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                            }

                            Spacer(minLength: 0)
                        }
                    }
                    .frame(minHeight: sidePanelHeight, maxHeight: sidePanelHeight, alignment: .topLeading)

                    panel("文本发送", subtitle: "自动切换输入法后发送文本到设备") {
                        GeometryReader { textSendProxy in
                            HStack(alignment: .top, spacing: 12) {
                                TextEditor(text: $vm.adbKeyboardText)
                                    .font(.mono(12))
                                    .scrollContentBackground(.hidden)
                                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                                    .padding(6)
                                    .background(
                                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                                            .fill(textSendEditorFill)
                                            .overlay {
                                                RoundedRectangle(cornerRadius: 12, style: .continuous)
                                                    .stroke(Theme.mist.opacity(0.95), lineWidth: 1)
                                            }
                                    )
                                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))

                                VStack(alignment: .leading, spacing: 8) {
                                    HStack(spacing: 10) {
                                        Toggle(isOn: $vm.adbKeyboardAutoSwitchIME) {
                                            textSendOptionLabel(
                                                "切换",
                                                help: "发送前自动切换到 ADBKeyBoard 输入法"
                                            )
                                        }
                                        .font(.bodySans(11.5, weight: .semibold))
                                        .toggleStyle(.checkbox)
                                        .controlSize(.small)
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                        .lineLimit(1)

                                        Toggle(isOn: $vm.adbKeyboardUseBase64) {
                                            textSendOptionLabel(
                                                "Base64",
                                                help: "先编码再发送，减少特殊字符输入异常"
                                            )
                                        }
                                        .font(.bodySans(11.5, weight: .semibold))
                                        .toggleStyle(.checkbox)
                                        .controlSize(.small)
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                        .lineLimit(1)
                                    }
                                    .frame(maxWidth: .infinity, alignment: .leading)

                                    VStack(spacing: 8) {
                                        textSendActionButton("从剪贴板填充") {
                                            vm.fillADBKeyboardTextFromClipboard()
                                        }

                                        textSendActionButton("发送文本") {
                                            vm.sendADBKeyboardText()
                                        }

                                        textSendActionButton("清空输入框") {
                                            vm.clearADBKeyboardTextOnDevice()
                                        }
                                    }
                                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
                                }
                                .frame(width: textSendControlColumnWidth, alignment: .topLeading)
                                .frame(maxHeight: .infinity, alignment: .topLeading)
                            }
                            .frame(width: textSendProxy.size.width, height: textSendProxy.size.height, alignment: .topLeading)
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                    }
                    .frame(minHeight: sidePanelHeight, maxHeight: sidePanelHeight, alignment: .topLeading)
                }
                .frame(maxWidth: .infinity, alignment: .topLeading)
                .frame(height: middleHeight, alignment: .top)

                panel("高级命令", subtitle: "可读预设 + 数字值；支持常量弹窗、快捷填入与直接发送") {
                    VStack(spacing: 10) {
                        Grid(alignment: .leading, horizontalSpacing: 8, verticalSpacing: 10) {
                            GridRow {
                                Menu {
                                    ForEach(keyEventPresets) { preset in
                                        Button(preset.displayTitle) {
                                            selectedKeyEventPresetCode = preset.code
                                            vm.adbKeyboardKeyCode = preset.code
                                        }
                                    }
                                } label: {
                                    commandDropdownLabel(selectedKeyEventPresetTitle)
                                }
                                .frame(width: commandDropdownWidth, alignment: .leading)
                                .menuIndicator(.hidden)
                                .gridColumnAlignment(.leading)

                                TextField("KeyEvent 代码", text: $vm.adbKeyboardKeyCode)
                                    .textFieldStyle(.roundedBorder)
                                    .frame(maxWidth: .infinity)
                                    .gridColumnAlignment(.leading)

                                commandAuxActionButton("常量列表", width: commandListButtonWidth) {
                                    inputConstantSheetTarget = .keyEvent
                                }
                                .gridColumnAlignment(.trailing)

                                commandSendActionButton("发送按键事件", width: commandSendButtonWidth) {
                                    vm.sendADBKeyboardKeyEvent()
                                }
                                .gridColumnAlignment(.trailing)
                            }

                            GridRow {
                                Menu {
                                    ForEach(editorActionPresets) { preset in
                                        Button(preset.displayTitle) {
                                            selectedEditorActionPresetCode = preset.code
                                            vm.adbKeyboardEditorCode = preset.code
                                        }
                                    }
                                } label: {
                                    commandDropdownLabel(selectedEditorActionPresetTitle)
                                }
                                .frame(width: commandDropdownWidth, alignment: .leading)
                                .menuIndicator(.hidden)
                                .gridColumnAlignment(.leading)

                                TextField("编辑动作代码", text: $vm.adbKeyboardEditorCode)
                                    .textFieldStyle(.roundedBorder)
                                    .frame(maxWidth: .infinity)

                                commandAuxActionButton("常量列表", width: commandListButtonWidth) {
                                    inputConstantSheetTarget = .editorAction
                                }

                                commandSendActionButton("发送编辑动作", width: commandSendButtonWidth) {
                                    vm.sendADBKeyboardEditorAction()
                                }
                            }

                            GridRow {
                                Menu {
                                    ForEach(unicodeSamplePresets) { preset in
                                        Button(preset.title) {
                                            selectedUnicodeSampleCodes = preset.codes
                                            vm.adbKeyboardUnicodeCodes = preset.codes
                                        }
                                    }
                                } label: {
                                    commandDropdownLabel(selectedUnicodeSampleTitle)
                                }
                                .frame(width: commandDropdownWidth, alignment: .leading)
                                .menuIndicator(.hidden)
                                .gridColumnAlignment(.leading)

                                TextField("Unicode 码点列表 (例如 128568,32,67,97,116)", text: $vm.adbKeyboardUnicodeCodes)
                                    .textFieldStyle(.roundedBorder)
                                    .frame(maxWidth: .infinity)
                                    .gridCellColumns(2)

                                commandSendActionButton("发送 Unicode", width: commandSendButtonWidth) {
                                    vm.sendADBKeyboardUnicodeCodes()
                                }
                            }

                            GridRow {
                                Menu {
                                    ForEach(metaCodeSamplePresets) { preset in
                                        Button(preset.title) {
                                            selectedMetaSampleCode = preset.codes
                                            vm.adbKeyboardMetaCode = preset.codes
                                        }
                                    }
                                } label: {
                                    commandDropdownLabel(selectedMetaSampleTitle)
                                }
                                .frame(width: commandDropdownWidth, alignment: .leading)
                                .menuIndicator(.hidden)
                                .gridColumnAlignment(.leading)

                                TextField("组合键 mcode", text: $vm.adbKeyboardMetaCode)
                                    .textFieldStyle(.roundedBorder)
                                    .frame(maxWidth: .infinity)
                                    .gridCellColumns(2)

                                commandSendActionButton("发送组合键", width: commandSendButtonWidth) {
                                    vm.sendADBKeyboardMetaCode()
                                }
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .topLeading)

                        Divider()

                        HStack {
                            Text("快捷按键")
                                .font(.bodySans(12, weight: .bold))
                                .foregroundStyle(Theme.ink)
                            Spacer()
                            Button("打开 KeyEvent 常量") {
                                inputConstantSheetTarget = .keyEvent
                            }
                            .buttonStyle(.bordered)

                            Button("打开编辑常量") {
                                inputConstantSheetTarget = .editorAction
                            }
                            .buttonStyle(.bordered)
                        }

                        HStack(spacing: 8) {
                            quickKeySendButton("回车", code: 66)
                            quickKeySendButton("退格", code: 67)
                            quickKeySendButton("空格", code: 62)
                            quickKeySendButton("Esc", code: 111)
                        }

                        HStack(spacing: 8) {
                            quickKeySendButton("返回", code: 4)
                            quickKeySendButton("主页", code: 3)
                            quickKeySendButton("菜单", code: 82)
                            quickKeySendButton("任务", code: 187)
                        }

                        Spacer(minLength: 0)
                    }
                }
                .frame(width: 468, height: middleHeight, alignment: .topLeading)
            }
            .frame(width: proxy.size.width, height: middleHeight, alignment: .topLeading)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }

    var keyEventPresets: [CommandCodePreset] {
        [
            CommandCodePreset(name: "KEYCODE_ENTER", code: "66", hint: "回车"),
            CommandCodePreset(name: "KEYCODE_DEL", code: "67", hint: "退格删除"),
            CommandCodePreset(name: "KEYCODE_SPACE", code: "62", hint: "空格"),
            CommandCodePreset(name: "KEYCODE_BACK", code: "4", hint: "返回"),
            CommandCodePreset(name: "KEYCODE_HOME", code: "3", hint: "主页"),
            CommandCodePreset(name: "KEYCODE_MENU", code: "82", hint: "菜单"),
            CommandCodePreset(name: "KEYCODE_APP_SWITCH", code: "187", hint: "任务切换"),
            CommandCodePreset(name: "KEYCODE_ESCAPE", code: "111", hint: "Esc"),
            CommandCodePreset(name: "KEYCODE_MOVE_HOME", code: "122", hint: "光标到行首"),
            CommandCodePreset(name: "KEYCODE_MOVE_END", code: "123", hint: "光标到行尾")
        ]
    }

    var editorActionPresets: [CommandCodePreset] {
        [
            CommandCodePreset(name: "IME_ACTION_UNSPECIFIED", code: "0", hint: "未指定"),
            CommandCodePreset(name: "IME_ACTION_NONE", code: "1", hint: "无动作"),
            CommandCodePreset(name: "IME_ACTION_GO", code: "2", hint: "前往"),
            CommandCodePreset(name: "IME_ACTION_SEARCH", code: "3", hint: "搜索"),
            CommandCodePreset(name: "IME_ACTION_SEND", code: "4", hint: "发送"),
            CommandCodePreset(name: "IME_ACTION_NEXT", code: "5", hint: "下一项"),
            CommandCodePreset(name: "IME_ACTION_DONE", code: "6", hint: "完成"),
            CommandCodePreset(name: "IME_ACTION_PREVIOUS", code: "7", hint: "上一项")
        ]
    }

    var unicodeSamplePresets: [UnicodeSamplePreset] {
        [
            UnicodeSamplePreset(title: "😀 笑脸", codes: "128512"),
            UnicodeSamplePreset(title: "😂 大笑", codes: "128514"),
            UnicodeSamplePreset(title: "👍 点赞", codes: "128077"),
            UnicodeSamplePreset(title: "🔥 火焰", codes: "128293"),
            UnicodeSamplePreset(title: "❤️ 红心", codes: "10084,65039"),
            UnicodeSamplePreset(title: "🎉 庆祝", codes: "127881"),
            UnicodeSamplePreset(title: "✅ 对勾", codes: "9989"),
            UnicodeSamplePreset(title: "✨ 星光", codes: "10024"),
            UnicodeSamplePreset(title: "© 版权", codes: "169"),
            UnicodeSamplePreset(title: "™ 商标", codes: "8482")
        ]
    }

    var metaCodeSamplePresets: [MetaCodeSamplePreset] {
        [
            MetaCodeSamplePreset(title: "Ctrl + A", codes: "4096,29"),
            MetaCodeSamplePreset(title: "Ctrl + C", codes: "4096,31"),
            MetaCodeSamplePreset(title: "Ctrl + V", codes: "4096,50"),
            MetaCodeSamplePreset(title: "Ctrl + X", codes: "4096,52"),
            MetaCodeSamplePreset(title: "Ctrl + Z", codes: "4096,54"),
            MetaCodeSamplePreset(title: "Ctrl + F", codes: "4096,33"),
            MetaCodeSamplePreset(title: "Ctrl + S", codes: "4096,47"),
            MetaCodeSamplePreset(title: "Ctrl + Enter", codes: "4096,66"),
            MetaCodeSamplePreset(title: "Shift + Tab", codes: "1,61"),
            MetaCodeSamplePreset(title: "Alt + Tab", codes: "2,61"),
            MetaCodeSamplePreset(title: "Ctrl(left) + A", codes: "4096+8192,29"),
            MetaCodeSamplePreset(title: "Shift + A", codes: "1,29")
        ]
    }

    var selectedKeyEventPresetTitle: String {
        keyEventPresets.first(where: { $0.code == selectedKeyEventPresetCode })?.displayTitle ?? "按键预设"
    }

    var selectedEditorActionPresetTitle: String {
        editorActionPresets.first(where: { $0.code == selectedEditorActionPresetCode })?.displayTitle ?? "编辑预设"
    }

    var selectedUnicodeSampleTitle: String {
        unicodeSamplePresets.first(where: { $0.codes == selectedUnicodeSampleCodes })?.title ?? "特殊内容"
    }

    var selectedMetaSampleTitle: String {
        metaCodeSamplePresets.first(where: { $0.codes == selectedMetaSampleCode })?.title ?? "组合按键"
    }

    func commandDropdownLabel(_ text: String) -> some View {
        HStack(spacing: 6) {
            Text(text)
                .font(.bodySans(12, weight: .semibold))
                .foregroundStyle(Theme.ink)
                .lineLimit(1)
                .truncationMode(.tail)
                .frame(maxWidth: .infinity, alignment: .leading)

            Image(systemName: "chevron.up.chevron.down")
                .font(.system(size: 10, weight: .semibold))
                .foregroundStyle(Theme.slate)
        }
        .padding(.horizontal, 10)
        .frame(height: 30)
        .background(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .fill(Color.white.opacity(0.82))
                .overlay {
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .stroke(Theme.mist.opacity(0.95), lineWidth: 1)
                }
        )
    }

    func quickKeySendButton(_ title: String, code: Int) -> some View {
        Button(title) {
            vm.sendQuickSystemKeyEvent(code: code, label: title)
        }
        .buttonStyle(.bordered)
        .frame(maxWidth: .infinity)
    }

    func constantPresetSheet(for target: InputConstantSheetTarget) -> some View {
        let presets = target == .editorAction ? editorActionPresets : keyEventPresets

        return VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text(target.title)
                    .font(.display(18, weight: .bold))
                    .foregroundStyle(Theme.ink)
                Spacer()
                Button("关闭") {
                    inputConstantSheetTarget = nil
                }
                .buttonStyle(.bordered)
                .keyboardShortcut(.cancelAction)
            }

            if let url = target.docURL {
                Link("打开官方文档", destination: url)
                    .font(.bodySans(12, weight: .semibold))
            }

            Text("点击“填入”可写入代码输入框，点击“填入并发送”会直接执行。")
                .font(.bodySans(12, weight: .medium))
                .foregroundStyle(Theme.slate)

            ScrollView {
                LazyVStack(spacing: 8) {
                    ForEach(presets) { preset in
                        constantPresetActionRow(preset, target: target)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .topLeading)
            }
        }
        .padding(16)
        .frame(minWidth: 860, minHeight: 560)
    }

    func constantPresetActionRow(_ preset: CommandCodePreset, target: InputConstantSheetTarget) -> some View {
        HStack(spacing: 8) {
            Text(preset.name)
                .font(.mono(11.5))
                .foregroundStyle(Theme.ink)
                .frame(maxWidth: .infinity, alignment: .leading)

            Text(preset.code)
                .font(.mono(11.5))
                .foregroundStyle(Theme.ocean)
                .frame(width: 42, alignment: .trailing)

            Text(preset.hint)
                .font(.bodySans(11, weight: .medium))
                .foregroundStyle(Theme.slate)
                .frame(width: 88, alignment: .leading)

            Button("填入") {
                applyConstantPreset(preset, target: target, shouldSend: false)
            }
            .buttonStyle(.bordered)

            Button("填入并发送") {
                applyConstantPreset(preset, target: target, shouldSend: true)
            }
            .buttonStyle(.borderedProminent)
            .tint(Theme.ocean)
        }
        .padding(.vertical, 4)
        .padding(.horizontal, 8)
        .background(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(Color.white.opacity(0.72))
                .overlay {
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .stroke(Color.white.opacity(0.8), lineWidth: 1)
                }
        )
    }

    func applyConstantPreset(_ preset: CommandCodePreset, target: InputConstantSheetTarget, shouldSend: Bool) {
        switch target {
        case .keyEvent:
            vm.adbKeyboardKeyCode = preset.code
            if shouldSend {
                vm.sendADBKeyboardKeyEvent()
            }
        case .editorAction:
            vm.adbKeyboardEditorCode = preset.code
            if shouldSend {
                vm.sendADBKeyboardEditorAction()
            }
        }
    }
}
