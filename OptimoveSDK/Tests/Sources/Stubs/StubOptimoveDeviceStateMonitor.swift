//  Copyright © 2019 Optimove. All rights reserved.

@testable import OptimoveSDK

final class StubOptimoveDeviceStateMonitor: OptimoveDeviceStateMonitor {

    var state: [OptimoveDeviceRequirement: Bool] = [
        .internet: true,
        .advertisingId: true,
        .userNotification: true
    ]

    func getStatus(for requirement: OptimoveDeviceRequirement, completion: @escaping ResultBlockWithBool) {
        completion(state[requirement]!)
    }

    func getStatuses(for requirement: [OptimoveDeviceRequirement],
                     completion: @escaping ([OptimoveDeviceRequirement: Bool]) -> Void) {
        fatalError("Not implemented")
    }

    func getMissingPermissions() -> [OptimoveDeviceRequirement] {
        fatalError("Not implemented")
    }
}
