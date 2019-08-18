//  Copyright © 2019 Optimove. All rights reserved.

import Foundation

public struct LoggerSettings {

    private struct Constants {
        struct Key {
            static let logLevel = "OPTIMOVE_MIN_LOG_LEVEL"
        }
    }

    public static var logLevelToShow: LogLevelCore = {
        if let minLogLevel = logLevel {
            return minLogLevel
        }
        return SDK.isStaging ? LogLevelCore.info : LogLevelCore.warn
    }()

    private static var logLevel: LogLevelCore? {
        guard let levelStr = SDK.getEnvironmentVariable(for: Constants.Key.logLevel) else { return nil }
        return LogLevelCore(string: levelStr.lowercased())
    }

}

