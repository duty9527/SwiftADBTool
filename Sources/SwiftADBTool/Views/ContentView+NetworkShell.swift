import SwiftUI

extension ContentView {
    var networkTab: some View {
        HStack(alignment: .top, spacing: 12) {
            panel("端口转发 Forward", subtitle: "本机端口映射到设备") {
                VStack(spacing: 10) {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("本地端口")
                                .font(.bodySans(11, weight: .semibold))
                                .foregroundStyle(Theme.slate)
                            TextField("例如 tcp:8080", text: $vm.forwardLocal)
                                .textFieldStyle(.roundedBorder)
                        }
                        VStack(alignment: .leading, spacing: 4) {
                            Text("远端端口")
                                .font(.bodySans(11, weight: .semibold))
                                .foregroundStyle(Theme.slate)
                            TextField("例如 tcp:8080", text: $vm.forwardRemote)
                                .textFieldStyle(.roundedBorder)
                        }
                    }

                    HStack {
                        Button("添加") {
                            vm.addForward()
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(Theme.mint)

                        Button("移除") {
                            vm.removeForward()
                        }
                        .buttonStyle(.bordered)

                        Button("刷新列表") {
                            vm.refreshForwardRules()
                        }
                        .buttonStyle(.bordered)

                        Spacer()
                    }

                    List(vm.forwardRules, id: \.self) { rule in
                        Text(rule)
                            .font(.mono(12.5))
                            .foregroundStyle(Theme.ink)
                            .lineLimit(1)
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
                    .frame(minHeight: 150, maxHeight: .infinity)
                }
            }

            panel("反向转发 Reverse", subtitle: "设备端口映射到本机") {
                VStack(spacing: 10) {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("远端端口")
                                .font(.bodySans(11, weight: .semibold))
                                .foregroundStyle(Theme.slate)
                            TextField("例如 tcp:8080", text: $vm.reverseRemote)
                                .textFieldStyle(.roundedBorder)
                        }
                        VStack(alignment: .leading, spacing: 4) {
                            Text("本地端口")
                                .font(.bodySans(11, weight: .semibold))
                                .foregroundStyle(Theme.slate)
                            TextField("例如 tcp:8080", text: $vm.reverseLocal)
                                .textFieldStyle(.roundedBorder)
                        }
                    }

                    HStack {
                        Button("添加") {
                            vm.addReverse()
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(Theme.mint)

                        Button("移除") {
                            vm.removeReverse()
                        }
                        .buttonStyle(.bordered)

                        Button("刷新列表") {
                            vm.refreshReverseRules()
                        }
                        .buttonStyle(.bordered)

                        Spacer()
                    }

                    List(vm.reverseRules, id: \.self) { rule in
                        Text(rule)
                            .font(.mono(12.5))
                            .foregroundStyle(Theme.ink)
                            .lineLimit(1)
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
                    .frame(minHeight: 150, maxHeight: .infinity)
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }

    var shellTab: some View {
        HStack(alignment: .top, spacing: 12) {
            panel("Shell 命令", subtitle: "执行 adb shell 命令") {
                VStack(spacing: 10) {
                    HStack {
                        TextField("输入 shell 命令", text: $vm.shellCommand)
                            .textFieldStyle(.roundedBorder)

                        Button("执行命令") {
                            vm.runShellCommand()
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(Theme.slate)

                        Button("查看全部") {
                            outputViewerTarget = .shell
                        }
                        .buttonStyle(.bordered)

                        Spacer()
                    }

                    ResizableTextEditor(
                        text: $vm.shellOutput,
                        height: $shellLogPaneHeight,
                        minHeight: 250,
                        maxHeight: 520,
                        font: .mono(12)
                    )
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)

            panel("Logcat 日志", subtitle: "抓取和清空设备日志") {
                VStack(spacing: 10) {
                    HStack {
                        Button("获取日志") {
                            vm.fetchLogcat()
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(Theme.ocean)

                        Button("清空日志") {
                            vm.clearLogcat()
                        }
                        .buttonStyle(.bordered)

                        Button("查看全部") {
                            outputViewerTarget = .logcat
                        }
                        .buttonStyle(.bordered)

                        Spacer()
                    }

                    ResizableTextEditor(
                        text: $vm.logcatOutput,
                        height: $shellLogPaneHeight,
                        minHeight: 250,
                        maxHeight: 520,
                        font: .mono(12)
                    )
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
    }

    var consolePanel: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("操作控制台 (Console)")
                    .font(.bodySans(14, weight: .bold))
                    .foregroundStyle(Theme.ink)

                Spacer()

                Button("查看全部") {
                    outputViewerTarget = .console
                }
                .buttonStyle(.bordered)

                Button("清空") {
                    vm.clearConsole()
                }
                .buttonStyle(.bordered)
            }

            ResizableTextEditor(
                text: $vm.consoleOutput,
                height: $consoleHeight,
                minHeight: 90,
                maxHeight: 220,
                font: .mono(12)
            )
        }
        .padding(14)
        .appCard(fill: Color.white)
    }

    func outputTextEditor(text: Binding<String>, minHeight: CGFloat) -> some View {
        TextEditor(text: text)
            .font(.mono(12.5))
            .scrollContentBackground(.hidden)
            .frame(minHeight: minHeight)
            .padding(8)
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(Theme.paper.opacity(0.90))
                    .overlay {
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .stroke(Theme.mist.opacity(0.95), lineWidth: 1)
                    }
            )
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }
    func outputBinding(for target: OutputViewerTarget) -> Binding<String> {
        switch target {
        case .shell:
            return $vm.shellOutput
        case .logcat:
            return $vm.logcatOutput
        case .console:
            return $vm.consoleOutput
        }
    }

    func fullOutputSheet(for target: OutputViewerTarget) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text(target.title)
                    .font(.display(18, weight: .bold))
                    .foregroundStyle(Theme.ink)

                Spacer()

                Button("关闭") {
                    outputViewerTarget = nil
                }
                .buttonStyle(.bordered)
                .keyboardShortcut(.cancelAction)
            }

            outputTextEditor(text: outputBinding(for: target), minHeight: 420)
                .frame(maxHeight: .infinity)
        }
        .padding(16)
        .frame(minWidth: 860, minHeight: 560)
    }
}
