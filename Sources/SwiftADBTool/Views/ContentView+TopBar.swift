import AppKit
import SwiftUI

extension ContentView {
    private var headerIconImage: NSImage? {
        if let pngURL = Bundle.module.url(forResource: "AppIcon-1024", withExtension: "png"),
           let image = NSImage(contentsOf: pngURL) {
            return image
        }
        if let icnsURL = Bundle.module.url(forResource: "AppIcon", withExtension: "icns"),
           let image = NSImage(contentsOf: icnsURL) {
            return image
        }
        return nil
    }

    var topBar: some View {
        VStack(spacing: 10) {
            HStack(spacing: 12) {
                HStack(spacing: 10) {
                    Group {
                        if let icon = headerIconImage {
                            Image(nsImage: icon)
                                .resizable()
                                .scaledToFill()
                        } else {
                            Image(systemName: "app")
                                .resizable()
                                .scaledToFit()
                                .padding(7)
                                .foregroundStyle(.white)
                                .background(
                                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                                        .fill(
                                            LinearGradient(
                                                colors: [Theme.ocean, Theme.mint],
                                                startPoint: .topLeading,
                                                endPoint: .bottomTrailing
                                            )
                                        )
                                )
                        }
                    }
                    .frame(width: 34, height: 34)
                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                    .overlay {
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .stroke(Color.white.opacity(0.35), lineWidth: 1)
                    }

                    VStack(alignment: .leading, spacing: 1) {
                        Text("SwiftADBTool")
                            .font(.display(20, weight: .bold))
                            .foregroundStyle(Theme.ink)
                        Text("macOS (Apple Silicon)")
                            .font(.bodySans(12, weight: .medium))
                            .foregroundStyle(Theme.slate)
                    }
                }

                Spacer(minLength: 10)

                if vm.isBusy {
                    ProgressView()
                        .controlSize(.small)
                        .tint(Theme.ocean)
                }

                Text(vm.statusText)
                    .font(.bodySans(12, weight: .medium))
                    .foregroundStyle(Theme.slate)
                    .lineLimit(1)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(
                        Capsule(style: .continuous)
                            .fill(Color.white.opacity(0.72))
                    )
            }

            HStack(spacing: 10) {
                labelTag("ADB 工具路径")

                TextField("/opt/homebrew/bin/adb", text: $vm.adbPath)
                    .textFieldStyle(.plain)
                    .font(.bodySans(13, weight: .medium))
                    .padding(.horizontal, 10)
                    .frame(height: 34)
                    .background(
                        RoundedRectangle(cornerRadius: 9, style: .continuous)
                            .fill(Color.white.opacity(0.82))
                            .overlay {
                                RoundedRectangle(cornerRadius: 9, style: .continuous)
                                    .stroke(Color.white.opacity(0.9), lineWidth: 1)
                            }
                    )

                Button("自动检测") {
                    vm.adbPath = AppViewModel.detectADBPath()
                }
                .buttonStyle(.bordered)

                Divider()
                    .frame(height: 18)

                labelTag("设备")

                Picker("设备", selection: $vm.selectedSerial) {
                    if vm.devices.isEmpty {
                        Text("未检测到设备").tag("")
                    }

                    ForEach(vm.devices) { device in
                        Text(device.displayName).tag(device.serial)
                    }
                }
                .labelsHidden()
                .pickerStyle(.menu)
                .frame(width: 320)

                Button("刷新设备") {
                    vm.refreshDevices()
                }
                .buttonStyle(.borderedProminent)
                .tint(Theme.ocean)
            }

            HStack(spacing: 8) {
                infoPill("ADB", vm.adbPath)
                infoPill("设备数量", "\(vm.devices.count)")

                if let selected = vm.selectedDevice {
                    infoPill("当前设备", "\(selected.displayName) · \(selected.state)")
                } else {
                    infoPill("当前设备", "未选择")
                }

                Spacer()
            }
        }
        .padding(14)
        .appCard(fill: Color.white)
    }
}
