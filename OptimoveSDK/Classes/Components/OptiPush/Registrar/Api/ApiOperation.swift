//  Copyright © 2020 Optimove. All rights reserved.

import Foundation

/// Describe operations that could be sent to MBaaS.
enum ApiOperation: CustomStringConvertible {
    /// Set a new or update an existed user.
    case setUser
    /// Add ut a user additional alias, as a visitior or a customer ID.
    case addUserAlias

    var description: String {
        switch self {
        case .setUser:
            return "set_user"
        case .addUserAlias:
            return "add_user_alias"
        }
    }
}
