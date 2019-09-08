//  Copyright © 2019 Optimove. All rights reserved.

import Foundation

protocol DeviceRequirementFetcherFactory {
    func createFetcher(for: OptimoveDeviceRequirement) -> Fetchable
}

final class DeviceRequirementFetcherFactoryImpl { }

extension DeviceRequirementFetcherFactoryImpl: DeviceRequirementFetcherFactory {

    func createFetcher(for requirement: OptimoveDeviceRequirement) -> Fetchable {
        switch requirement {
        case .userNotification:
            return NotificationPermissionFetcher()
        }
    }
}
