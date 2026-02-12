import Foundation

enum RebootMode: String, CaseIterable, Identifiable {
    case system
    case recovery
    case bootloader
    case sideload

    var id: String { rawValue }

    var adbArguments: [String] {
        switch self {
        case .system:
            return ["reboot"]
        case .recovery:
            return ["reboot", "recovery"]
        case .bootloader:
            return ["reboot", "bootloader"]
        case .sideload:
            return ["reboot", "sideload"]
        }
    }

    var title: String {
        switch self {
        case .system: return "系统"
        case .recovery: return "恢复模式"
        case .bootloader: return "Bootloader"
        case .sideload: return "Sideload"
        }
    }
}

struct ADBDevice: Identifiable, Hashable, Sendable {
    let serial: String
    let state: String
    let attributes: [String: String]

    var id: String { serial }

    var displayName: String {
        let model = attributes["model"]?.replacingOccurrences(of: "_", with: " ")
        let product = attributes["product"]?.replacingOccurrences(of: "_", with: " ")

        if let model, !model.isEmpty {
            return "\(model) (\(serial))"
        }

        if let product, !product.isEmpty {
            return "\(product) (\(serial))"
        }

        return serial
    }

    var subtitle: String {
        let transport = attributes["transport_id"].map { "transport:\($0)" } ?? ""
        if transport.isEmpty {
            return state
        }
        return "\(state) · \(transport)"
    }
}

struct RemotePathEntry: Identifiable, Hashable, Sendable {
    let name: String
    let fullPath: String
    let isDirectory: Bool

    var id: String { fullPath }

    var displayName: String {
        isDirectory ? "\(name)/" : name
    }
}

struct LocalPathEntry: Identifiable, Hashable, Sendable {
    let name: String
    let fullPath: String
    let isDirectory: Bool

    var id: String { fullPath }
}

struct InputMethodEntry: Identifiable, Hashable, Sendable {
    let id: String
    let isEnabled: Bool
    let isCurrent: Bool

    var displayName: String {
        let suffix: String
        if isCurrent {
            suffix = "当前"
        } else if isEnabled {
            suffix = "已启用"
        } else {
            suffix = "未启用"
        }
        return "\(id) (\(suffix))"
    }
}

struct CommandResult: Sendable {
    let command: String
    let stdout: String
    let stderr: String
    let status: Int32
}

enum ADBError: LocalizedError {
    case launchFailure(String)
    case commandFailed(CommandResult)
    case invalidResponse(String)
    case emptySelection(String)

    var errorDescription: String? {
        switch self {
        case .launchFailure(let message):
            return message
        case .commandFailed(let result):
            let stderr = result.stderr.trimmingCharacters(in: .whitespacesAndNewlines)
            if stderr.isEmpty {
                return "Command failed (\(result.status)): \(result.command)"
            }
            return "Command failed (\(result.status)): \(stderr)"
        case .invalidResponse(let message):
            return message
        case .emptySelection(let message):
            return message
        }
    }
}
