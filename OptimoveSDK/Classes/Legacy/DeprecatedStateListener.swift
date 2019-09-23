//  Copyright © 2019 Optimove. All rights reserved.

import Foundation

public enum OptimoveDeviceRequirement: Int, CaseIterable {
    case userNotification = 2
}

// TODO: Delete the protocol declaration after SDK version 2.3.0
@available(*, deprecated, message: "This method will be deleted in the next version. Instead of subscribing as an listener use Optimove SDK directly.")
public protocol OptimoveSuccessStateListener: class {
    func optimove(
        _ optimove: Optimove,
        didBecomeActiveWithMissingPermissions missingPermissions: [OptimoveDeviceRequirement]
    )
}
