import Foundation
import os

let subsystem = Bundle.main.bundleIdentifier ?? "com.torus.utils"

public struct TorusUtilsLogger {
    static let inactiveLog = OSLog.disabled
    static let network = OSLog(subsystem: subsystem, category: "network")
}

func getTorusLogger(log: OSLog = .default, type: OSLogType = .default) -> OSLog {
    var logCheck: OSLog { utilsLogType.rawValue <= type.rawValue ? log : TorusUtilsLogger.inactiveLog }
    return logCheck
}
