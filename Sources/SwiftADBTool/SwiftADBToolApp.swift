import SwiftUI
import AppKit

@main
struct SwiftADBToolApp: App {
    private let fixedWindowSize = NSSize(width: 1260, height: 820)

    init() {
        NSApplication.shared.setActivationPolicy(.regular)
        if let iconURL = Bundle.module.url(forResource: "AppIcon", withExtension: "icns"),
           let iconImage = NSImage(contentsOf: iconURL) {
            NSApplication.shared.applicationIconImage = iconImage
            let workspace = NSWorkspace.shared
            _ = workspace.setIcon(iconImage, forFile: Bundle.main.bundlePath, options: [])
            if let executablePath = Bundle.main.executablePath {
                _ = workspace.setIcon(iconImage, forFile: executablePath, options: [])
            }
        }
    }

    var body: some Scene {
        WindowGroup("SwiftADBTool") {
            ContentView()
                .preferredColorScheme(.light)
                .frame(
                    minWidth: fixedWindowSize.width,
                    idealWidth: fixedWindowSize.width,
                    maxWidth: fixedWindowSize.width,
                    minHeight: fixedWindowSize.height,
                    idealHeight: fixedWindowSize.height,
                    maxHeight: fixedWindowSize.height
                )
                .onAppear {
                    NSApplication.shared.activate(ignoringOtherApps: true)
                    DispatchQueue.main.async {
                        applyFixedWindowPolicy()
                        NSApplication.shared.windows.first?.center()
                        NSApplication.shared.windows.first?.makeKeyAndOrderFront(nil)
                    }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        applyFixedWindowPolicy()
                    }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                        applyFixedWindowPolicy()
                    }
                }
        }
        .windowResizability(.contentSize)
        .defaultSize(width: fixedWindowSize.width, height: fixedWindowSize.height)
    }

    private func applyFixedWindowPolicy() {
        for window in NSApplication.shared.windows {
            window.setContentSize(fixedWindowSize)
            window.minSize = fixedWindowSize
            window.maxSize = fixedWindowSize
            window.styleMask.remove(.resizable)
            window.standardWindowButton(.zoomButton)?.isEnabled = false
            if let rootView = window.contentView {
                applyScrollerPolicy(in: rootView)
            }
        }
    }

    private func applyScrollerPolicy(in view: NSView) {
        if let scrollView = view as? NSScrollView {
            scrollView.scrollerStyle = .overlay
            scrollView.autohidesScrollers = true
            scrollView.scrollerKnobStyle = .dark
            scrollView.verticalScroller?.controlSize = .small
            scrollView.horizontalScroller?.controlSize = .small
        }

        for subview in view.subviews {
            applyScrollerPolicy(in: subview)
        }
    }
}
