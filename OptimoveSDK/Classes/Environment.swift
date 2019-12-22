//  Copyright © 2019 Optimove. All rights reserved.

import Foundation
import OptimoveCore

struct AppEnvironment {

    static let isSandboxAps: Bool = {
        do {
            return try MobileProvision.read().entitlements.apsEnvironment == .development
        } catch {
            Logger.warn("the app does not contain the embedded.mobileprovision")
            /// If the app does not contain the embedded.mobileprovision which is stripped out by Apple when the app is submitted to store, then it is highly likely that it is from Apple Store.
            return false
        }
    }()

}
