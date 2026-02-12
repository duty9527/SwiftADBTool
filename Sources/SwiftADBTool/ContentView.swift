import Foundation
import SwiftUI
import AppKit
import UniformTypeIdentifiers

enum ToolTab: String, CaseIterable, Identifiable {
    case device
    case apps
    case files
    case network
    case input
    case shell

    var id: String { rawValue }

    var title: String {
        switch self {
        case .device: return "设备"
        case .apps: return "应用"
        case .files: return "文件管理"
        case .network: return "网络"
        case .input: return "文本输入"
        case .shell: return "命令与日志"
        }
    }

    var icon: String {
        switch self {
        case .device: return "iphone.gen3"
        case .apps: return "square.grid.2x2"
        case .files: return "folder"
        case .network: return "point.3.connected.trianglepath.dotted"
        case .input: return "keyboard"
        case .shell: return "terminal"
        }
    }
}

enum OutputViewerTarget: String, Identifiable {
    case shell
    case logcat
    case console

    var id: String { rawValue }

    var title: String {
        switch self {
        case .shell:
            return "Shell 输出"
        case .logcat:
            return "Logcat 输出"
        case .console:
            return "Console 输出"
        }
    }
}

enum InputConstantSheetTarget: String, Identifiable {
    case keyEvent
    case editorAction

    var id: String { rawValue }

    var title: String {
        switch self {
        case .keyEvent:
            return "KeyEvent 常量列表"
        case .editorAction:
            return "EditorAction 常量列表"
        }
    }

    var docURL: URL? {
        switch self {
        case .keyEvent:
            return URL(string: "https://developer.android.com/reference/android/view/KeyEvent")
        case .editorAction:
            return URL(string: "https://developer.android.com/reference/android/view/inputmethod/EditorInfo")
        }
    }
}

struct CommandCodePreset: Identifiable, Hashable {
    let name: String
    let code: String
    let hint: String

    var id: String { "\(name)-\(code)" }
    var displayTitle: String { "\(name) (\(code))" }
}

struct UnicodeSamplePreset: Identifiable, Hashable {
    let title: String
    let codes: String

    var id: String { "\(title)-\(codes)" }
}

struct MetaCodeSamplePreset: Identifiable, Hashable {
    let title: String
    let codes: String

    var id: String { "\(title)-\(codes)" }
}

struct ContentView: View {
    @StateObject var vm = AppViewModel()
    @State var selectedTab: ToolTab = .device

    @State var shellLogPaneHeight: CGFloat = 250
    @State var consoleHeight: CGFloat = 120
    @State var isRemoteDropTargeted = false
    @State var remoteRenameTarget: RemotePathEntry?
    @State var remoteRenameText = ""
    @State var remoteDeleteTarget: RemotePathEntry?
    @State var outputViewerTarget: OutputViewerTarget?
    @State var inputConstantSheetTarget: InputConstantSheetTarget?
    @State var selectedKeyEventPresetCode = ""
    @State var selectedEditorActionPresetCode = ""
    @State var selectedUnicodeSampleCodes = ""
    @State var selectedMetaSampleCode = ""

    var body: some View {
        ZStack {
            Theme.backgroundGradient
                .ignoresSafeArea()

            VStack(spacing: 14) {
                topBar

                TabView(selection: $selectedTab) {
                    deviceTab
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                        .tag(ToolTab.device)
                        .tabItem {
                            Label(ToolTab.device.title, systemImage: ToolTab.device.icon)
                        }

                    appsTab
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                        .tag(ToolTab.apps)
                        .tabItem {
                            Label(ToolTab.apps.title, systemImage: ToolTab.apps.icon)
                        }

                    filesTab
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                        .tag(ToolTab.files)
                        .tabItem {
                            Label(ToolTab.files.title, systemImage: ToolTab.files.icon)
                        }

                    networkTab
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                        .tag(ToolTab.network)
                        .tabItem {
                            Label(ToolTab.network.title, systemImage: ToolTab.network.icon)
                        }

                    inputTab
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                        .tag(ToolTab.input)
                        .tabItem {
                            Label(ToolTab.input.title, systemImage: ToolTab.input.icon)
                        }

                    shellTab
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                        .tag(ToolTab.shell)
                        .tabItem {
                            Label(ToolTab.shell.title, systemImage: ToolTab.shell.icon)
                        }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .layoutPriority(1)

                consolePanel
            }
            .padding(18)
        }
        .task {
            vm.initialLoad()
            DispatchQueue.main.async {
                refreshScrollerStyleAcrossWindows()
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                refreshScrollerStyleAcrossWindows()
            }
        }
        .onChange(of: selectedTab) { newTab in
            if newTab == .files {
                vm.loadFileManagersIfNeeded()
            } else if newTab == .input,
                      vm.inputMethodEntries.isEmpty,
                      !vm.selectedSerial.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                vm.loadInputMethodList()
            }
            DispatchQueue.main.async {
                refreshScrollerStyleAcrossWindows()
            }
        }
        .onChange(of: vm.selectedSerial) { _ in
            vm.resetRemoteNavigation(to: "/sdcard/")
            vm.remotePathEntries = []
            vm.selectedRemoteEntryPath = ""
            vm.inputMethodEntries = []
            vm.selectedInputMethodID = ""
            vm.currentInputMethodID = ""
            vm.adbKeyboardIMEList = ""
            if selectedTab == .files {
                vm.loadRemotePathEntries()
            } else if selectedTab == .input {
                vm.loadInputMethodList()
            }
            DispatchQueue.main.async {
                refreshScrollerStyleAcrossWindows()
            }
        }
        .sheet(item: $outputViewerTarget) { target in
            fullOutputSheet(for: target)
        }
        .sheet(item: $inputConstantSheetTarget) { target in
            constantPresetSheet(for: target)
        }
    }

    private func refreshScrollerStyleAcrossWindows() {
        for window in NSApplication.shared.windows {
            if let root = window.contentView {
                applyScrollerStyle(in: root)
            }
        }
    }

    private func applyScrollerStyle(in view: NSView) {
        if let scrollView = view as? NSScrollView {
            scrollView.scrollerStyle = .overlay
            scrollView.autohidesScrollers = true
            scrollView.scrollerKnobStyle = .dark
            scrollView.verticalScroller?.controlSize = .small
            scrollView.horizontalScroller?.controlSize = .small
        }

        for subview in view.subviews {
            applyScrollerStyle(in: subview)
        }
    }
}
