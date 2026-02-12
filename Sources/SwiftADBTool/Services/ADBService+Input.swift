import Foundation

extension ADBService {
    func listInputMethods(serial: String, adbPath: String) throws -> String {
        try execute(
            args: ["shell", "ime", "list", "-a"],
            serial: serial,
            adbPath: adbPath
        ).stdout
    }

    func listInputMethodIDs(all: Bool, serial: String, adbPath: String) throws -> [String] {
        let candidates = listInputMethodOutputCandidates(all: all)
        guard let firstArgs = candidates.first else { return [] }

        let firstOutput = try execute(args: firstArgs, serial: serial, adbPath: adbPath).stdout
        let firstParsed = parseInputMethodIDs(from: firstOutput)
        if !firstParsed.isEmpty {
            return firstParsed
        }

        for args in candidates.dropFirst() {
            guard let output = try? execute(args: args, serial: serial, adbPath: adbPath).stdout else {
                continue
            }
            let parsed = parseInputMethodIDs(from: output)
            if !parsed.isEmpty {
                return parsed
            }
        }

        return firstParsed
    }

    func currentInputMethod(serial: String, adbPath: String) throws -> String {
        if let output = try? execute(
            args: ["shell", "settings", "get", "secure", "default_input_method"],
            serial: serial,
            adbPath: adbPath
        ).stdout {
            let value = output.trimmingCharacters(in: .whitespacesAndNewlines)
            if value != "null" {
                return value
            }
        }

        let dumpsys = try execute(
            args: ["shell", "dumpsys", "input_method"],
            serial: serial,
            adbPath: adbPath
        ).stdout
        return parseCurrentInputMethod(from: dumpsys)
    }

    func enableInputMethod(_ id: String, serial: String, adbPath: String) throws -> String {
        try execute(
            args: ["shell", "ime", "enable", id],
            serial: serial,
            adbPath: adbPath
        ).stdout
    }

    func setInputMethod(_ id: String, serial: String, adbPath: String) throws -> String {
        try execute(
            args: ["shell", "ime", "set", id],
            serial: serial,
            adbPath: adbPath
        ).stdout
    }

    func resetInputMethod(serial: String, adbPath: String) throws -> String {
        try execute(
            args: ["shell", "ime", "reset"],
            serial: serial,
            adbPath: adbPath
        ).stdout
    }

    private func adbKeyboardBroadcast(
        action: String,
        serial: String,
        adbPath: String,
        arguments: [String] = []
    ) throws -> String {
        let args = ["shell", "am", "broadcast", "-a", action] + arguments
        return try execute(args: args, serial: serial, adbPath: adbPath).stdout
    }

    func sendADBKeyboardText(_ text: String, serial: String, adbPath: String) throws -> String {
        try adbKeyboardBroadcast(
            action: "ADB_INPUT_TEXT",
            serial: serial,
            adbPath: adbPath,
            arguments: ["--es", "msg", text]
        )
    }

    func sendADBKeyboardTextBase64(_ text: String, serial: String, adbPath: String) throws -> String {
        let encoded = Data(text.utf8).base64EncodedString()
        return try adbKeyboardBroadcast(
            action: "ADB_INPUT_B64",
            serial: serial,
            adbPath: adbPath,
            arguments: ["--es", "msg", encoded]
        )
    }

    func sendADBKeyboardKeyEvent(code: Int, serial: String, adbPath: String) throws -> String {
        try adbKeyboardBroadcast(
            action: "ADB_INPUT_CODE",
            serial: serial,
            adbPath: adbPath,
            arguments: ["--ei", "code", String(code)]
        )
    }

    func sendShellKeyEvent(code: Int, serial: String, adbPath: String) throws -> String {
        if let output = try? execute(
            args: ["shell", "input", "keyevent", String(code)],
            serial: serial,
            adbPath: adbPath
        ).stdout {
            return output
        }

        return try execute(
            args: ["shell", "cmd", "input", "keyevent", String(code)],
            serial: serial,
            adbPath: adbPath
        ).stdout
    }

    func sendADBKeyboardEditorAction(code: Int, serial: String, adbPath: String) throws -> String {
        try adbKeyboardBroadcast(
            action: "ADB_EDITOR_CODE",
            serial: serial,
            adbPath: adbPath,
            arguments: ["--ei", "code", String(code)]
        )
    }

    func sendADBKeyboardUnicodeCodes(codesCSV: String, serial: String, adbPath: String) throws -> String {
        try adbKeyboardBroadcast(
            action: "ADB_INPUT_CHARS",
            serial: serial,
            adbPath: adbPath,
            arguments: ["--eia", "chars", codesCSV]
        )
    }

    func sendADBKeyboardMetaCode(_ metaCode: String, serial: String, adbPath: String) throws -> String {
        try adbKeyboardBroadcast(
            action: "ADB_INPUT_TEXT",
            serial: serial,
            adbPath: adbPath,
            arguments: ["--es", "mcode", metaCode]
        )
    }

    func clearADBKeyboardText(serial: String, adbPath: String) throws -> String {
        try adbKeyboardBroadcast(
            action: "ADB_CLEAR_TEXT",
            serial: serial,
            adbPath: adbPath
        )
    }
}
