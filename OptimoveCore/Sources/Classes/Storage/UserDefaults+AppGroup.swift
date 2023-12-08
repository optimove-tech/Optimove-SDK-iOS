//  Copyright © 2023 Optimove. All rights reserved.

import Foundation

public extension UserDefaults {
    static func optimoveAppGroup() -> UserDefaults {
        let suiteName = Bundle.optimoveAppGroupIdentifier
        guard let userDefaults = UserDefaults(suiteName: suiteName) else {
            let message = """
            Unable to initialize UserDefault with suit name "\(suiteName)".
            Highly possible that the client forgot to add the app group as described in the documentation.
            Link: https://github.com/optimove-tech/Optimove-SDK-iOS/wiki/SDK-Setup-Capabilities
            """
            fatalError(message)
        }
        return userDefaults
    }
}
