import AppKit
import Foundation
import UniformTypeIdentifiers

enum PanelHelper {
    @MainActor
    static func chooseFile(allowedExtensions: [String]? = nil) -> String? {
        let panel = NSOpenPanel()
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false
        panel.canChooseFiles = true
        panel.resolvesAliases = true

        if let allowedExtensions, !allowedExtensions.isEmpty {
            panel.allowedContentTypes = allowedExtensions.compactMap { ext in
                UTType(filenameExtension: ext)
            }
        }

        let response = panel.runModal()
        guard response == .OK, let url = panel.url else {
            return nil
        }

        return url.path
    }

    @MainActor
    static func chooseDirectory() -> String? {
        let panel = NSOpenPanel()
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = true
        panel.canChooseFiles = false
        panel.resolvesAliases = true

        let response = panel.runModal()
        guard response == .OK, let url = panel.url else {
            return nil
        }

        return url.path
    }

    @MainActor
    static func chooseFilesAndDirectories() -> [String] {
        let panel = NSOpenPanel()
        panel.allowsMultipleSelection = true
        panel.canChooseDirectories = true
        panel.canChooseFiles = true
        panel.resolvesAliases = true

        let response = panel.runModal()
        guard response == .OK else {
            return []
        }

        return panel.urls.map { $0.path }
    }

    @MainActor
    static func saveFile(defaultName: String, allowedExtensions: [String]) -> String? {
        let panel = NSSavePanel()
        panel.nameFieldStringValue = defaultName

        if !allowedExtensions.isEmpty {
            panel.allowedContentTypes = allowedExtensions.compactMap { ext in
                UTType(filenameExtension: ext)
            }
        }

        let response = panel.runModal()
        guard response == .OK, let url = panel.url else {
            return nil
        }

        return url.path
    }
}
