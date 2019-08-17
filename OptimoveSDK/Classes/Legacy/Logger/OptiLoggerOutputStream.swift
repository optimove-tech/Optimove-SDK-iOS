//  Copyright © 2019 Optimove. All rights reserved.

import Foundation
import OptimoveCore

@objc public protocol OptiLoggerOutputStream: LoggerStream {
    var isVisibleToClient: Bool { get }
    func log(level: LogLevel, fileName: String, methodName: String, logModule: String?, message: String)
}
