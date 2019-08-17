//  Copyright © 2019 Optimove. All rights reserved.

import Foundation
import os.log

final class ConsoleLoggerStream: LoggerStream {

    var policy: LoggerStreamPolicy = .userDefined

    func log(level: LogLevel, fileName: String, methodName: String, logModule: String?, message: String) {
        os_log(
            "%{public}@ %{public}@ %{public}@",
            log: OSLog.consoleStream,
            type: convert(logLevel: level),
            message, fileName, methodName
        )
    }

    private func convert(logLevel: LogLevel) -> OSLogType {
        switch logLevel {
        case .error:
            return .error
        case .warn:
            return .info
        case .info:
            return .info
        case .debug:
            return .default
        }
    }
}

public extension OSLog {
    static var subsystem = Bundle.main.bundleIdentifier!
}

extension OSLog {
    static let consoleStream = OSLog(subsystem: subsystem, category: "ConsoleStream")
}
