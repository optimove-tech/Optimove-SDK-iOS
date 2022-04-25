//  Copyright © 2020 Optimove. All rights reserved.

import Foundation

/// Describe operations that could be sent to MBaaS.
enum ApiOperation: CustomStringConvertible {
    /// Set or update the installation data.
    case setInstallation

    var description: String {
        switch self {
        case .setInstallation:
            return "set_installation"
        }
    }
}
