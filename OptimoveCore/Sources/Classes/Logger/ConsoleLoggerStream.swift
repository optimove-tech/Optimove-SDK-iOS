//  Copyright © 2019 Optimove. All rights reserved.

import Foundation
import os.log

public final class ConsoleLoggerStream: LoggerStream {

    public var policy: LoggerStreamPolicy = .userDefined

    public init() {}

    public func log(level: LogLevelCore, fileName: String, methodName: String, logModule: String?, message: String) {
        os_log(
            "%{public}@",
            log: OSLog.consoleStream,
            type: convert(logLevel: level),
            message
        )
    }

    private func convert(logLevel: LogLevelCore) -> OSLogType {
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
    static let consoleStream = OSLog(subsystem: subsystem, category: "Optimove")
}
