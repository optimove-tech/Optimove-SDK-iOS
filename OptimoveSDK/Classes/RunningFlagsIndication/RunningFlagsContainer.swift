//  Copyright © 2019 Optimove. All rights reserved.

import Foundation

final class RunningFlagsIndication {

    static var isSdkRunning = false
    static var isInitializerRunning = false

    static func isSdkNeedInitializing() -> Bool {
        return !(isSdkRunning || isInitializerRunning)
    }

}
