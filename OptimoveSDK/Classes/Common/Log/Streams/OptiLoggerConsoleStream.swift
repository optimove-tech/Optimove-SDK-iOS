//  Copyright © 2019 Optimove. All rights reserved.

import Foundation
import os.log
import OptimoveCore

final class OptiLoggerConsoleStream: NSObject, OptiLoggerOutputStream {

    func log(level: LogLevel, fileName: String, methodName: String, logModule: String?, message: String) {
        optiLog(level: level, fileName: fileName, methodName: methodName, logModule: logModule, message: message)
    }

    var isVisibleToClient: Bool {
        return true
    }

    private func optiLog(level: LogLevel, fileName: String, methodName: String, logModule: String?, message: String) {
        os_log(
            "%{public}@ %{public}@ %{public}@",
            log: OSLog.consoleStream,
            type: convert(logLevel: level),
            fileName, methodName, message
        )
    }

    private func convert(logLevel: LogLevel) -> OSLogType {
        switch logLevel {
        case .error:
            return .error
        case .warn:
            return .debug
        case .debug:
            return .debug
        case .info:
            return .info
        }
    }
}

extension OSLog {
    static let consoleStream = OSLog(subsystem: subsystem, category: "ConsoleStream")
}
