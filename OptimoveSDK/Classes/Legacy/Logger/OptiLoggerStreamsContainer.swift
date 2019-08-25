//  Copyright © 2019 Optimove. All rights reserved.

import Foundation
import OptimoveCore

/// Contains an array of a log receivers.
@objc public final class OptiLoggerStreamsContainer: NSObject {

    /// The method transmit a log event to a set of receivers.
    ///
    /// - Parameters:
    ///   - level: The log level
    ///   - fileName: The file name of invoked log
    ///   - methodName: The method name of invoked log
    ///   - logModule: The module name of invoked log
    ///   - message: The message passed with log
    @objc(logWithLevel:fileName:methodName:logModule:message:)
    public static func log(
        level: LogLevel,
        fileName: String?,
        methodName: String?,
        logModule: String?,
        _ message: String
    ) {
        MultiplexLoggerStream.log(
            level: level.convert(),
            fileName: fileName,
            methodName: methodName,
            logModule: logModule,
            message
        )
    }

    /// Add a stream to a log receivers.
    ///
    /// - Parameter stream: The stream for addition.
    @objc public static func add(stream: OptiLoggerOutputStream) {
        MultiplexLoggerStream.add(stream: OptiLoggerOutputStreamAdapter(adaptee: stream))
    }

    /// Remove a stream from a log receivers.
    /// - Warning: Current version does not maintains deletion from receivers.
    ///
    /// - Parameter stream: The stream for deletion.
    @objc public static func remove(stream: OptiLoggerOutputStream) {
        // TODO: Solve a deletion inside MultiplexLoggerStream, without breaking a public API.
        // MultiplexLoggerStream.remove(stream: stream)
    }
}

final class OptiLoggerOutputStreamAdapter: LoggerStream {

    private let adaptee: OptiLoggerOutputStream

    init(adaptee: OptiLoggerOutputStream) {
        self.adaptee = adaptee
    }

    var policy: LoggerStreamPolicy {
        return adaptee.isVisibleToClient ? .all : .userDefined
    }

    func log(level: LogLevelCore, fileName: String, methodName: String, logModule: String?, message: String) {
        adaptee.log(level: LogLevel(rawValue: level.rawValue)!, fileName: fileName, methodName: methodName, logModule: logModule, message: message)
    }

}

extension LogLevel {

    func convert() -> LogLevelCore {
        return LogLevelCore(rawValue: self.rawValue)!
    }

}
