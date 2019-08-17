//  Copyright © 2019 Optimove. All rights reserved.

import Foundation
import OptimoveCore

@objc public final class OptiLoggerStreamsContainer: NSObject {

    @objc(logWithLevel:fileName:methodName:logModule:message:)
    public static func log(
        level: LogLevel,
        fileName: String?,
        methodName: String?,
        logModule: String?,
        _ message: String
    ) {
        MultiplexLoggerStream.log(
            level: level,
            fileName: fileName,
            methodName: methodName,
            logModule: logModule,
            message
        )
    }

    @objc public static func add(stream: OptiLoggerOutputStream) {
        MultiplexLoggerStream.add(stream: stream)
    }

    @objc public static func remove(stream: OptiLoggerOutputStream) {
        MultiplexLoggerStream.remove(stream: stream)
    }
}
