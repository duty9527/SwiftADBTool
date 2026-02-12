import Foundation

extension ADBService {
    func listDevices(adbPath: String) throws -> [ADBDevice] {
        let output = try execute(args: ["devices", "-l"], adbPath: adbPath).stdout

        let lines = output
            .split(whereSeparator: \.isNewline)
            .map { String($0).trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }

        guard !lines.isEmpty else {
            return []
        }

        var devices: [ADBDevice] = []

        for line in lines.dropFirst() {
            let pieces = line.split(separator: " ", omittingEmptySubsequences: true)
            if pieces.count < 2 {
                continue
            }

            let serial = String(pieces[0])
            let state = String(pieces[1])
            var attributes: [String: String] = [:]

            if pieces.count > 2 {
                for token in pieces.dropFirst(2) {
                    let keyValue = token.split(separator: ":", maxSplits: 1, omittingEmptySubsequences: true)
                    if keyValue.count == 2 {
                        attributes[String(keyValue[0])] = String(keyValue[1])
                    }
                }
            }

            devices.append(ADBDevice(serial: serial, state: state, attributes: attributes))
        }

        return devices.sorted { $0.serial < $1.serial }
    }

    func shell(command: String, serial: String, adbPath: String) throws -> String {
        let trimmed = command.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            return ""
        }

        if !containsShellMetaCharacters(trimmed), let tokens = tokenizeSimpleShellCommand(trimmed) {
            let directOutput = try execute(args: ["shell"] + tokens, serial: serial, adbPath: adbPath).stdout

            if tokens.count >= 2, tokens[0] == "ime", tokens[1] == "list" {
                let helpHint = "ime <command>:"
                if directOutput.contains(helpHint) {
                    let fallbackArgs = ["shell", "cmd", "input_method", "list"] + Array(tokens.dropFirst(2))
                    if let fallbackOutput = try? execute(args: fallbackArgs, serial: serial, adbPath: adbPath).stdout,
                       !fallbackOutput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                        return fallbackOutput
                    }
                }
            }

            return directOutput
        }

        return try execute(args: ["shell", "sh", "-c", trimmed], serial: serial, adbPath: adbPath).stdout
    }

    func connect(host: String, adbPath: String) throws -> String {
        try execute(args: ["connect", host], adbPath: adbPath).stdout
    }

    func disconnect(host: String?, adbPath: String) throws -> String {
        if let host, !host.isEmpty {
            return try execute(args: ["disconnect", host], adbPath: adbPath).stdout
        }
        return try execute(args: ["disconnect"], adbPath: adbPath).stdout
    }

    func tcpip(port: String, serial: String, adbPath: String) throws -> String {
        try execute(args: ["tcpip", port], serial: serial, adbPath: adbPath).stdout
    }

    func reboot(mode: RebootMode, serial: String, adbPath: String) throws -> String {
        try execute(args: mode.adbArguments, serial: serial, adbPath: adbPath).stdout
    }

    func install(apkPath: String, replace: Bool, serial: String, adbPath: String) throws -> String {
        var args = ["install"]
        if replace {
            args.append("-r")
        }
        args.append(apkPath)
        return try execute(args: args, serial: serial, adbPath: adbPath).stdout
    }

    func uninstall(packageName: String, keepData: Bool, serial: String, adbPath: String) throws -> String {
        var args = ["uninstall"]
        if keepData {
            args.append("-k")
        }
        args.append(packageName)
        return try execute(args: args, serial: serial, adbPath: adbPath).stdout
    }

    func listPackages(serial: String, adbPath: String) throws -> [String] {
        let output = try execute(
            args: ["shell", "pm", "list", "packages"],
            serial: serial,
            adbPath: adbPath
        ).stdout

        return output
            .split(whereSeparator: \.isNewline)
            .map { String($0).trimmingCharacters(in: .whitespacesAndNewlines) }
            .compactMap { line in
                guard line.hasPrefix("package:") else { return nil }
                return String(line.dropFirst("package:".count))
            }
            .sorted()
    }

    func launch(packageName: String, activity: String?, serial: String, adbPath: String) throws -> String {
        if let activity, !activity.isEmpty {
            return try execute(
                args: ["shell", "am", "start", "-n", "\(packageName)/\(activity)"],
                serial: serial,
                adbPath: adbPath
            ).stdout
        }

        return try execute(
            args: ["shell", "monkey", "-p", packageName, "-c", "android.intent.category.LAUNCHER", "1"],
            serial: serial,
            adbPath: adbPath
        ).stdout
    }

    func stop(packageName: String, serial: String, adbPath: String) throws -> String {
        try execute(
            args: ["shell", "am", "force-stop", packageName],
            serial: serial,
            adbPath: adbPath
        ).stdout
    }

    func push(localPath: String, remotePath: String, serial: String, adbPath: String) throws -> String {
        try execute(
            args: ["push", localPath, remotePath],
            serial: serial,
            adbPath: adbPath
        ).stdout
    }

    func pull(remotePath: String, localPath: String, serial: String, adbPath: String) throws -> String {
        try execute(
            args: ["pull", remotePath, localPath],
            serial: serial,
            adbPath: adbPath
        ).stdout
    }
}
