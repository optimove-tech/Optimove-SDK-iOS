//  Copyright © 2019 Optimove. All rights reserved.

import Foundation
import OptimoveCore

@objc public final class OptiLoggerStreamsContainer: NSObject {

    private struct Constants {
        static let delimiter = "/"
        static let placeholder = ""
    }

    static var outputStreams: [ObjectIdentifier: OptiLoggerOutputStream] = [:]

    private static let logQueue = DispatchQueue(label: "com.optimove.sdk.log")

    @objc(logWithLevel:fileName:methodName:logModule:message:)
    public static func log(
        level: LogLevel,
        fileName: String?,
        methodName: String?,
        logModule: String?,
        _ message: String
    ) {
        logQueue.async {
            outputStreams.values.forEach {
                if $0.isVisibleToClient {
                    if LoggerSettings.logLevelToShow <= level {
                        $0.log(
                            level: level,
                            fileName: fileName?.components(separatedBy: Constants.delimiter).last ?? Constants.placeholder,
                            methodName: methodName ?? Constants.placeholder,
                            logModule: logModule,
                            message: message
                        )
                    }
                } else {
                    $0.log(
                        level: level,
                        fileName: fileName?.components(separatedBy: Constants.delimiter).last ?? Constants.placeholder,
                        methodName: methodName ?? Constants.placeholder,
                        logModule: logModule,
                        message: message
                    )
                }
            }
        }
    }

    @objc public static func add(stream: OptiLoggerOutputStream) {
        outputStreams[ObjectIdentifier(stream)] = stream
    }

    @objc public static func remove(stream: OptiLoggerOutputStream) {
        outputStreams.removeValue(forKey: ObjectIdentifier(stream))
    }
}
