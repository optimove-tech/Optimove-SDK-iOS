//  Copyright © 2019 Optimove. All rights reserved.

import Foundation

public protocol LoggerStream: AnyObject {
    var policy: LoggerStreamFilter { get }
    func log(level: LogLevelCore, fileName: String, methodName: String, logModule: String?, message: String)
}

/// Allow to mutate loggers, when the tenant's config file was successfully fetched.
public protocol MutableLoggerStream: LoggerStream {
    var tenantId: Int { get set }
    var endpoint: URL { get set }
    /// Configurable value that used by log filters. Default state is `false`.
    var isProductionLogsEnabled: Bool { get set }
}

/// Define a log level that passes a filter before it will be sent to the stream's destination target.
///
/// - all: Allow all logs.
/// - custom: Use a custom filtering
public enum LoggerStreamFilter {
    case all
    case custom(filter: (_ level: LogLevelCore, _ isRemote: Bool) -> Bool)
}
