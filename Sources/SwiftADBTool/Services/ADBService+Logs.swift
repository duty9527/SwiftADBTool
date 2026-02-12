import Foundation

extension ADBService {
    func fetchLogcat(serial: String, adbPath: String) throws -> String {
        try execute(args: ["logcat", "-d", "-v", "time"], serial: serial, adbPath: adbPath).stdout
    }

    func clearLogcat(serial: String, adbPath: String) throws -> String {
        try execute(args: ["logcat", "-c"], serial: serial, adbPath: adbPath).stdout
    }
}
