//  Copyright © 2019 Optimove. All rights reserved.

import Foundation

@objc(OptimoveLoggerStream)
public protocol LoggerStream: AnyObject {
    var policy: LoggerStreamPolicy { get }
    func log(level: LogLevel, fileName: String, methodName: String, logModule: String?, message: String)
}

public protocol MutableLoggerStream: LoggerStream {
    var tenantId: Int { get set }
    var endpoint: URL { get set }
}

/// Define a log level that passes a filter before it will be sent to the stream's destination target.
///
/// - all: Allow all logs.
/// - userDefined: Allow logs that pass level filter defined by user's `OPTIMOVE_MIN_LOG_LEVEL` key.
@objc public enum LoggerStreamPolicy: Int {
    case all
    case userDefined
}
