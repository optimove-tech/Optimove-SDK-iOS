//  Copyright © 2019 Optimove. All rights reserved.

import Foundation

public struct SDK {

    public static var environment: Environment {
        return isStaging ? .dev : .prod
    }

    public static var isStaging: Bool {
        #if DEBUG
            return true
        #else
            return false
        #endif
    }

}
