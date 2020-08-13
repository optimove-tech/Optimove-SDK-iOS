//  Copyright © 2019 Optimove. All rights reserved.

import Foundation
import os.log

public final class ConsoleLoggerStream: LoggerStream {

    public var policy: LoggerStreamFilter {
        return LoggerStreamFilter.custom { [unowned self] (level, _) -> Bool in
            return self.isAllowedByFiltring(level: level)
        }
    }

    public init() {}

    public func log(level: LogLevelCore, fileName: String, methodName: String, logModule: String?, message: String) {
        os_log(
            "%{public}@",
            log: OSLog.consoleStream,
            type: OSLogType(logLevel: level),
            message
        )
    }

    private func isAllowedByFiltring(level: LogLevelCore) -> Bool {
        let defaultState = SdkEnvironment.isDebugEnabled ? LogLevelCore.debug : LogLevelCore.warn
        return level >= defaultState
    }
}

public extension OSLog {
    static var subsystem = Bundle.main.bundleIdentifier!
}

extension OSLog {
    static let consoleStream = OSLog(subsystem: subsystem, category: "Optimove")
}

extension OSLogType {

    init(logLevel: LogLevelCore) {
        switch logLevel {
        case .fatal:
            self = .fault
        case .error:
            self = .error
        case .warn:
            self = .info
        case .info:
            self = .info
        case .debug:
            self = .default
        }
    }
}
