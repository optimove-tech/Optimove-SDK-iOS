import Foundation

enum OptimoveComponentType {
    case optiPush
    case optiTrack
    case realtime

    static let numberOfTypes = 3
}

class RunningFlagsIndication {

    static let queue = DispatchQueue(label: "com.optimove.sdkState")

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

    static func isAllComponentsFaulted() -> Bool {
        for (_, running) in componentsRunningStates {
            if running {
                return false
            }
        }
        return true
    }
}
