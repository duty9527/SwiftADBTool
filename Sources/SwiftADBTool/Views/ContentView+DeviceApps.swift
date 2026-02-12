import SwiftUI

extension ContentView {
    var deviceTab: some View {
        HStack(alignment: .top, spacing: 12) {
            panel("连接与模式设置", subtitle: "连接、断开、TCP/IP、重启模式") {
                VStack(alignment: .leading, spacing: 10) {
                    settingsBlock("无线连接") {
                        HStack {
                            TextField("例如: 192.168.1.20:5555", text: $vm.connectionHost)
                                .textFieldStyle(.roundedBorder)

                            Button("连接") {
                                vm.connect()
                            }
                            .buttonStyle(.borderedProminent)
                            .tint(Theme.mint)

                            Button("断开") {
                                vm.disconnectTarget()
                            }
                            .buttonStyle(.bordered)
                        }
                    }

                    settingsBlock("传输模式") {
                        HStack {
                            labelTag("TCP/IP 端口")

                            TextField("5555", text: $vm.tcpipPort)
                                .textFieldStyle(.roundedBorder)
                                .frame(width: 90)

                            Button("应用") {
                                vm.tcpip()
                            }
                            .buttonStyle(.bordered)

                            Spacer()
                        }
                    }

                    settingsBlock("重启控制") {
                        HStack {
                            labelTag("重启模式")

                            Picker("重启模式", selection: $vm.rebootMode) {
                                ForEach(RebootMode.allCases) { mode in
                                    Text(mode.title).tag(mode)
                                }
                            }
                            .labelsHidden()
                            .pickerStyle(.menu)
                            .frame(width: 170)

                            Button("发送重启") {
                                vm.rebootDevice()
                            }
                            .buttonStyle(.borderedProminent)
                            .tint(Theme.coral)

                            Spacer()
                        }

                        Text(selectedRebootModeHint)
                            .font(.bodySans(11, weight: .medium))
                            .foregroundStyle(Theme.slate)
                    }

                    Spacer(minLength: 0)
                }
            }
            .frame(maxHeight: .infinity, alignment: .topLeading)

            panel("设备信息", subtitle: "显示设备列表与当前设备详情") {
                VStack(alignment: .leading, spacing: 10) {
                    if vm.devices.isEmpty {
                        Text("当前没有可用设备。请连接 USB 并点“刷新设备”。")
                            .font(.bodySans(13, weight: .medium))
                            .foregroundStyle(Theme.slate)
                    } else {
                        ScrollView {
                            LazyVStack(spacing: 6) {
                                ForEach(vm.devices) { device in
                                    DeviceRow(
                                        device: device,
                                        isSelected: vm.selectedSerial == device.serial,
                                        onSelect: { vm.selectedSerial = device.serial }
                                    )
                                }
                            }
                        }
                        .frame(minHeight: 100)
                    }

                    Divider()

                    if let device = vm.selectedDevice {
                        detailRow(label: "序列号", value: device.serial)
                        detailRow(label: "状态", value: device.state)
                        detailRow(label: "型号", value: device.attributes["model"] ?? "-")
                        detailRow(label: "产品", value: device.attributes["product"] ?? "-")
                        detailRow(label: "传输ID", value: device.attributes["transport_id"] ?? "-")
                    } else {
                        Text("未选择设备")
                            .font(.bodySans(14, weight: .medium))
                            .foregroundStyle(Theme.slate)
                    }
                }
            }
            .frame(width: 420)
            .frame(maxHeight: .infinity, alignment: .top)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }

    var appsTab: some View {
        HStack(alignment: .top, spacing: 12) {
            panel("安装与控制", subtitle: "支持文件选择和拖拽 APK 安装") {
                VStack(spacing: 12) {
                    HStack {
                        FileDropTextField(
                            placeholder: "拖拽 .apk 到这里",
                            text: $vm.apkPath,
                            allowedExtensions: ["apk"],
                            allowDirectory: false
                        )

                        Button("选择 APK") {
                            if let path = PanelHelper.chooseFile(allowedExtensions: ["apk"]) {
                                vm.apkPath = path
                            }
                        }
                        .buttonStyle(.bordered)

                        Toggle("覆盖安装(-r)", isOn: $vm.installReplace)
                            .toggleStyle(.switch)
                            .frame(width: 120)

                        Button("安装") {
                            vm.installAPK()
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(Theme.mint)
                    }

                    Text("提示: 可直接从 Finder 拖拽 APK 到输入框")
                        .font(.bodySans(12, weight: .medium))
                        .foregroundStyle(Theme.slate)
                        .frame(maxWidth: .infinity, alignment: .leading)

                    HStack {
                        TextField("卸载包名，例如 com.example.app", text: $vm.uninstallPackage)
                            .textFieldStyle(.roundedBorder)

                        Toggle("保留数据(-k)", isOn: $vm.uninstallKeepData)
                            .toggleStyle(.switch)
                            .frame(width: 120)

                        Button("卸载") {
                            vm.uninstallPackageNow()
                        }
                        .buttonStyle(.bordered)
                        .tint(Theme.coral)
                    }

                    Divider()

                    HStack {
                        TextField("包名 (package)", text: $vm.launchPackage)
                            .textFieldStyle(.roundedBorder)

                        TextField("Activity (可选)", text: $vm.launchActivity)
                            .textFieldStyle(.roundedBorder)
                    }

                    HStack {
                        Button("启动应用") {
                            vm.launchApp()
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(Theme.ocean)

                        Button("停止应用") {
                            vm.stopApp()
                        }
                        .buttonStyle(.bordered)

                        Spacer()
                    }
                }
            }

            panel("应用包列表", subtitle: "点击包名可自动填入启动/卸载输入框") {
                VStack(spacing: 10) {
                    HStack {
                        TextField("按关键词筛选包名", text: $vm.packageFilter)
                            .textFieldStyle(.roundedBorder)

                        Button("加载包列表") {
                            vm.loadPackages()
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(Theme.ocean)
                    }

                    List(vm.filteredPackages, id: \.self) { item in
                        Text(item)
                            .font(.mono(12.5))
                            .foregroundStyle(Theme.ink)
                            .lineLimit(1)
                            .onTapGesture {
                                vm.launchPackage = item
                                vm.uninstallPackage = item
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
                    .frame(minHeight: 220, maxHeight: .infinity)
                }
            }
            .frame(width: 430)
            .frame(maxHeight: .infinity, alignment: .top)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }
}
