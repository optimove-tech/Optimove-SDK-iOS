//  Copyright © 2019 Optimove. All rights reserved.

import Foundation

enum RunningFlagsIndication {
    static var isSdkRunning = false
    static var isInitializerRunning = false
    static var isSdkNeedInitializing: Bool {
        return !(isSdkRunning || isInitializerRunning)
    }
}
