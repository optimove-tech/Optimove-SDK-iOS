//  Copyright © 2019 Optimove. All rights reserved.

import Foundation

@objc public enum LogLevel: Int  {
    case debug = 0
    case info = 1
    case warn = 2
    case error = 3
}

extension LogLevel: Comparable {

    public static func < (lhs: LogLevel, rhs: LogLevel) -> Bool {
        return lhs.rawValue < rhs.rawValue
    }
}
