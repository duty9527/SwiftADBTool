import Foundation

extension ADBService {
    func deleteRemotePath(path: String, serial: String, adbPath: String) throws -> String {
        let targetPath = normalizeRemoteItemPath(path)
        if targetPath == "/" {
            throw ADBError.invalidResponse("Refusing to delete root directory")
        }

        let quotedTarget = shellQuote(targetPath)
        return try execute(
            args: ["shell", "rm", "-rf", quotedTarget],
            serial: serial,
            adbPath: adbPath
        ).stdout
    }

    func renameRemotePath(from oldPath: String, to newPath: String, serial: String, adbPath: String) throws -> String {
        let sourcePath = normalizeRemoteItemPath(oldPath)
        let destinationPath = normalizeRemoteItemPath(newPath)

        if sourcePath == "/" {
            throw ADBError.invalidResponse("Refusing to rename root directory")
        }

        let quotedSource = shellQuote(sourcePath)
        let quotedDestination = shellQuote(destinationPath)
        return try execute(
            args: ["shell", "mv", quotedSource, quotedDestination],
            serial: serial,
            adbPath: adbPath
        ).stdout
    }

    func listRemotePathEntries(path: String, serial: String, adbPath: String) throws -> [RemotePathEntry] {
        let directory = normalizeRemoteDirectoryPath(path)
        let output = try execute(
            args: ["shell", "ls", "-1", "-p", directory],
            serial: serial,
            adbPath: adbPath
        ).stdout

        var entries: [RemotePathEntry] = output
            .split(whereSeparator: \.isNewline)
            .map { String($0).trimmingCharacters(in: .whitespacesAndNewlines) }
            .compactMap { raw in
                guard !raw.isEmpty, raw != ".", raw != ".." else {
                    return nil
                }

                let isDirectory = raw.hasSuffix("/")
                let name = isDirectory ? String(raw.dropLast()) : raw
                guard !name.isEmpty else {
                    return nil
                }

                let fullPath = joinRemotePath(baseDirectory: directory, name: name, isDirectory: isDirectory)
                return RemotePathEntry(name: name, fullPath: fullPath, isDirectory: isDirectory)
            }

        entries.sort { lhs, rhs in
            if lhs.isDirectory != rhs.isDirectory {
                return lhs.isDirectory
            }
            return lhs.name.localizedStandardCompare(rhs.name) == .orderedAscending
        }

        return entries
    }

    func screenshot(saveURL: URL, serial: String, adbPath: String) throws {
        let (_, data) = try executeRaw(
            args: ["exec-out", "screencap", "-p"],
            serial: serial,
            adbPath: adbPath
        )

        guard !data.isEmpty else {
            throw ADBError.invalidResponse("Screenshot command returned empty data")
        }

        try data.write(to: saveURL)
    }

    func screenRecord(saveURL: URL, durationSeconds: Int, serial: String, adbPath: String) throws -> String {
        let clipped = min(max(durationSeconds, 1), 180)
        let remotePath = "/sdcard/__adb_tools_record.mp4"

        _ = try execute(
            args: ["shell", "screenrecord", "--time-limit", String(clipped), remotePath],
            serial: serial,
            adbPath: adbPath
        )

        _ = try execute(
            args: ["pull", remotePath, saveURL.path],
            serial: serial,
            adbPath: adbPath
        )

        _ = try? execute(
            args: ["shell", "rm", "-f", remotePath],
            serial: serial,
            adbPath: adbPath
        )

        return "Saved to \(saveURL.path)"
    }

    func forward(local: String, remote: String, serial: String, adbPath: String) throws -> String {
        try execute(args: ["forward", local, remote], serial: serial, adbPath: adbPath).stdout
    }

    func removeForward(local: String, serial: String, adbPath: String) throws -> String {
        try execute(args: ["forward", "--remove", local], serial: serial, adbPath: adbPath).stdout
    }

    func listForward(serial: String, adbPath: String) throws -> [String] {
        let output = try execute(args: ["forward", "--list"], serial: serial, adbPath: adbPath).stdout

        return output
            .split(whereSeparator: \.isNewline)
            .map { String($0).trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
    }

    func reverse(remote: String, local: String, serial: String, adbPath: String) throws -> String {
        try execute(args: ["reverse", remote, local], serial: serial, adbPath: adbPath).stdout
    }

    func removeReverse(remote: String, serial: String, adbPath: String) throws -> String {
        try execute(args: ["reverse", "--remove", remote], serial: serial, adbPath: adbPath).stdout
    }

    func listReverse(serial: String, adbPath: String) throws -> [String] {
        let output = try execute(args: ["reverse", "--list"], serial: serial, adbPath: adbPath).stdout

        return output
            .split(whereSeparator: \.isNewline)
            .map { String($0).trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
    }
}
