import Foundation

actor ADBService {
    private final class ThreadSafeDataBuffer: @unchecked Sendable {
        private var storage = Data()
        private let lock = NSLock()

        func set(_ data: Data) {
            lock.lock()
            storage = data
            lock.unlock()
        }

        func value() -> Data {
            lock.lock()
            defer { lock.unlock() }
            return storage
        }
    }

    func normalizeADBPath(_ adbPath: String) -> String {
        let trimmed = adbPath.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? "adb" : trimmed
    }

    func normalizeRemoteDirectoryPath(_ path: String) -> String {
        var normalized = path.trimmingCharacters(in: .whitespacesAndNewlines)
        if normalized.isEmpty {
            return "/"
        }

        if !normalized.hasPrefix("/") {
            normalized = "/" + normalized
        }

        if normalized != "/" && !normalized.hasSuffix("/") {
            normalized += "/"
        }

        return normalized
    }

    func joinRemotePath(baseDirectory: String, name: String, isDirectory: Bool) -> String {
        let base = normalizeRemoteDirectoryPath(baseDirectory)
        let cleanName = name.trimmingCharacters(in: .whitespacesAndNewlines)

        var fullPath: String
        if base == "/" {
            fullPath = "/" + cleanName
        } else {
            fullPath = base + cleanName
        }

        if isDirectory && !fullPath.hasSuffix("/") {
            fullPath += "/"
        }

        return fullPath
    }

    func shellQuote(_ value: String) -> String {
        "'" + value.replacingOccurrences(of: "'", with: "'\"'\"'") + "'"
    }

    func normalizeRemoteItemPath(_ path: String) -> String {
        var normalized = path.trimmingCharacters(in: .whitespacesAndNewlines)
        if normalized.isEmpty {
            return "/"
        }

        if !normalized.hasPrefix("/") {
            normalized = "/" + normalized
        }

        if normalized != "/" && normalized.hasSuffix("/") {
            normalized.removeLast()
        }

        return normalized
    }

    func containsShellMetaCharacters(_ command: String) -> Bool {
        let metaCharacters = CharacterSet(charactersIn: "|&;<>()$`*?[]{}~")
        return command.rangeOfCharacter(from: metaCharacters) != nil
    }

    func tokenizeSimpleShellCommand(_ command: String) -> [String]? {
        var tokens: [String] = []
        var current = ""
        var inSingleQuote = false
        var inDoubleQuote = false
        var isEscaping = false

        for character in command {
            if isEscaping {
                current.append(character)
                isEscaping = false
                continue
            }

            if character == "\\" && !inSingleQuote {
                isEscaping = true
                continue
            }

            if character == "'" && !inDoubleQuote {
                inSingleQuote.toggle()
                continue
            }

            if character == "\"" && !inSingleQuote {
                inDoubleQuote.toggle()
                continue
            }

            if character.isWhitespace && !inSingleQuote && !inDoubleQuote {
                if !current.isEmpty {
                    tokens.append(current)
                    current = ""
                }
                continue
            }

            current.append(character)
        }

        if isEscaping || inSingleQuote || inDoubleQuote {
            return nil
        }

        if !current.isEmpty {
            tokens.append(current)
        }

        return tokens.isEmpty ? nil : tokens
    }

    func parseInputMethodIDs(from output: String) -> [String] {
        var ids: [String] = []
        var seen: Set<String> = []

        for rawLine in output.split(whereSeparator: \.isNewline) {
            let line = rawLine.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !line.isEmpty else { continue }

            var candidate: String?

            if let mIDRange = line.range(of: "mId=") {
                let after = line[mIDRange.upperBound...]
                candidate = after.split(whereSeparator: \.isWhitespace).first.map(String.init)
            } else if line.contains("/") {
                candidate = line.split(whereSeparator: \.isWhitespace).first.map(String.init)
            }

            guard let id = candidate?.trimmingCharacters(in: .whitespacesAndNewlines), !id.isEmpty else {
                continue
            }

            guard id.contains("/") else {
                continue
            }

            if seen.insert(id).inserted {
                ids.append(id)
            }
        }

        return ids
    }

    func parseCurrentInputMethod(from dumpsysOutput: String) -> String {
        for rawLine in dumpsysOutput.split(whereSeparator: \.isNewline) {
            let line = rawLine.trimmingCharacters(in: .whitespacesAndNewlines)
            if let range = line.range(of: "mCurMethodId=") {
                let value = line[range.upperBound...].trimmingCharacters(in: .whitespacesAndNewlines)
                if !value.isEmpty {
                    return value
                }
            }

            if let range = line.range(of: "mCurrentInputMethod=") {
                let value = line[range.upperBound...].trimmingCharacters(in: .whitespacesAndNewlines)
                if !value.isEmpty {
                    return value
                }
            }
        }

        return ""
    }

    func listInputMethodOutputCandidates(all: Bool) -> [[String]] {
        if all {
            return [
                ["shell", "ime", "list", "-a", "-s"],
                ["shell", "ime", "list", "-s", "-a"],
                ["shell", "cmd", "input_method", "list", "-a", "-s"],
                ["shell", "cmd", "input_method", "list", "-s", "-a"],
                ["shell", "ime", "list", "-a"]
            ]
        }

        return [
            ["shell", "ime", "list", "-s"],
            ["shell", "cmd", "input_method", "list", "-s"],
            ["shell", "ime", "list"]
        ]
    }

    func executeRaw(
        args: [String],
        serial: String?,
        adbPath: String
    ) throws -> (CommandResult, Data) {
        let adbExecutable = normalizeADBPath(adbPath)
        var allArgs = [adbExecutable]

        if let serial, !serial.isEmpty {
            allArgs.append(contentsOf: ["-s", serial])
        }

        allArgs.append(contentsOf: args)

        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/env")
        process.arguments = allArgs

        let stdoutPipe = Pipe()
        let stderrPipe = Pipe()
        process.standardOutput = stdoutPipe
        process.standardError = stderrPipe

        let stdoutBuffer = ThreadSafeDataBuffer()
        let stderrBuffer = ThreadSafeDataBuffer()
        let readGroup = DispatchGroup()

        readGroup.enter()
        DispatchQueue.global(qos: .userInitiated).async {
            let data = stdoutPipe.fileHandleForReading.readDataToEndOfFile()
            stdoutBuffer.set(data)
            readGroup.leave()
        }

        readGroup.enter()
        DispatchQueue.global(qos: .userInitiated).async {
            let data = stderrPipe.fileHandleForReading.readDataToEndOfFile()
            stderrBuffer.set(data)
            readGroup.leave()
        }

        do {
            try process.run()
        } catch {
            throw ADBError.launchFailure("Unable to launch adb. Check path: \(adbExecutable)")
        }

        process.waitUntilExit()
        readGroup.wait()

        let stdoutData = stdoutBuffer.value()
        let stderrData = stderrBuffer.value()
        let stdout = String(data: stdoutData, encoding: .utf8) ?? ""
        let stderr = String(data: stderrData, encoding: .utf8) ?? ""

        let commandText = ([adbExecutable] + allArgs.dropFirst()).joined(separator: " ")

        let result = CommandResult(
            command: commandText,
            stdout: stdout,
            stderr: stderr,
            status: process.terminationStatus
        )

        if result.status != 0 {
            throw ADBError.commandFailed(result)
        }

        return (result, stdoutData)
    }

    func execute(
        args: [String],
        serial: String? = nil,
        adbPath: String
    ) throws -> CommandResult {
        let (result, _) = try executeRaw(args: args, serial: serial, adbPath: adbPath)
        return result
    }
}
