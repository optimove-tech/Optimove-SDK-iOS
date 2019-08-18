//  Copyright © 2019 Optimove. All rights reserved.

import Foundation

/// Receiver of logs of OptimoveSDK.
@objc public protocol OptiLoggerOutputStream {
    /// Describe if the stream could receive logs independently from project settings.
    /// If `true` all logs will be received, despite on a project settings.
    var isVisibleToClient: Bool { get }
    /// The method receive a log for the  Optimove SDK.
    ///
    /// - Parameters:
    ///   - level: The log level
    ///   - fileName: The file name of the invoked log
    ///   - methodName: The method name of the invoked log
    ///   - logModule: The module name of the invoked log
    ///   - message: The message passed with the log
    func log(level: LogLevel, fileName: String, methodName: String, logModule: String?, message: String)
}
