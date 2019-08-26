//  Copyright © 2019 Optimove. All rights reserved.

import Foundation

enum OptimoveComponentType {
    case optiPush
    case optiTrack
    case realtime
}

final class RunningFlagsIndication {

    static var isSdkRunning = false

    static var isInitializerRunning = false
    static var componentsRunningStates = [OptimoveComponentType: Bool]()

    static func isSdkNeedInitializing() -> Bool {
        return !(isSdkRunning || isInitializerRunning)
    }

    static func isComponentRunning(_ component: OptimoveComponentType) -> Bool {
        return componentsRunningStates[component] ?? false
    }

    static func setComponentRunningFlag(component: OptimoveComponentType, state: Bool) {
        componentsRunningStates[component] = state
    }
}
