//  Copyright © 2019 Optimove. All rights reserved.

import Foundation

enum OptimoveHandlerType {
    case optiPush
    case optiTrack
    case realtime
}

final class RunningFlagsIndication {

    static var isSdkRunning = false

    static var isInitializerRunning = false
    static var componentsRunningStates = [OptimoveHandlerType: Bool]()

    static func isSdkNeedInitializing() -> Bool {
        return !(isSdkRunning || isInitializerRunning)
    }

    static func isComponentRunning(_ component: OptimoveHandlerType) -> Bool {
        return componentsRunningStates[component] ?? false
    }

    static func setComponentRunningFlag(component: OptimoveHandlerType, state: Bool) {
        componentsRunningStates[component] = state
    }
}
