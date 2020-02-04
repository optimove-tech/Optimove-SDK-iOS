//  Copyright © 2020 Optimove. All rights reserved.

import Foundation

/// Describe operations that could be sent to MBaaS.
enum ApiOperation: CustomStringConvertible {
    /// Set a new or update an existed user.
    case setUser

    var description: String {
        switch self {
        case .setUser:
            return "set_user"
        }
    }
}
