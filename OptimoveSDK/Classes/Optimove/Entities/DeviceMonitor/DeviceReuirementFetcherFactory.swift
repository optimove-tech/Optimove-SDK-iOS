//  Copyright © 2019 Optimove. All rights reserved.

import Foundation

protocol DeviceRequirementFetcherFactory {
    func createFetcher(for: OptimoveDeviceRequirement) -> Fetchable
}

final class DeviceRequirementFetcherFactoryImpl { }

extension DeviceRequirementFetcherFactoryImpl: DeviceRequirementFetcherFactory {
    
    func createFetcher(for requirement: OptimoveDeviceRequirement) -> Fetchable {
        switch requirement {
        case .advertisingId:
            return AdvertisingIdPermissionFetcher()
        case .userNotification:
            return NotificationPermissionFetcher()
        case .internet:
            return NetworkCapabilitiesFetcher()
        }
    }
}
