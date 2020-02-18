//  Copyright © 2020 Optimove. All rights reserved.

import Foundation
import OptimoveCore

// MARK: - Deprecated: SDK state observing

public enum OptimoveDeviceRequirement: Int, CaseIterable {
    case userNotification = 2
}

@available(*, deprecated, message: "This method will be deleted in the next version. Instead of subscribing as an listener use Optimove SDK directly.")
public protocol OptimoveSuccessStateListener: class {
    func optimove(
        _ optimove: Optimove,
        didBecomeActiveWithMissingPermissions missingPermissions: [OptimoveDeviceRequirement]
    )
}

extension Optimove {

    @available(*, deprecated, message: "No need to register for lifecycle events. Use the SDK directly.")
    public func registerSuccessStateListener(_ listener: OptimoveSuccessStateListener) {
        listener.optimove(self, didBecomeActiveWithMissingPermissions: [])
    }

    @available(*, deprecated, message: "No need to unregister from lifecycle events anymore. Use the SDK directly.")
    public func unregisterSuccessStateListener(_ listener: OptimoveSuccessStateListener) { }

}
