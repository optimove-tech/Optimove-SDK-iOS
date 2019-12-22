//  Copyright © 2019 Optimove. All rights reserved.

import OptimoveCore

struct Environment {

    static var isDevelopmentApn: Bool {
        do {
            return try MobileProvision.read().entitlements.apsEnvironment == .development
        } catch {
            Logger.error("Unable to read a mobileprovision profile. \(error.localizedDescription)")
            // Return `false` as the most saftiest strategy for production.
            return false
        }
    }

}
