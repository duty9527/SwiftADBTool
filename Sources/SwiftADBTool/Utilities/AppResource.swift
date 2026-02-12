import AppKit
import Foundation

enum AppResource {
    private static let moduleBundleName = "SwiftADBTool_SwiftADBTool.bundle"

    static func image(named name: String, ext: String) -> NSImage? {
        guard let url = resourceURL(named: name, ext: ext) else {
            return nil
        }
        return NSImage(contentsOf: url)
    }

    static func resourceURL(named name: String, ext: String) -> URL? {
        if let url = Bundle.main.url(forResource: name, withExtension: ext) {
            return url
        }

        if let bundle = bundleCandidate(at: Bundle.main.bundleURL),
           let url = bundle.url(forResource: name, withExtension: ext) {
            return url
        }

        if let executableDir = Bundle.main.executableURL?.deletingLastPathComponent(),
           let bundle = bundleCandidate(at: executableDir),
           let url = bundle.url(forResource: name, withExtension: ext) {
            return url
        }

        return nil
    }

    private static func bundleCandidate(at baseURL: URL) -> Bundle? {
        let candidate = baseURL.appendingPathComponent(moduleBundleName)
        return Bundle(url: candidate)
    }
}
