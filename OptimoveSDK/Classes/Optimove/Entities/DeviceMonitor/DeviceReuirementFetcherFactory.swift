import Foundation

class DeviceReuirementFetcherFactory {
    static var dictionary: [OptimoveDeviceRequirement: Fetchable] = [
        OptimoveDeviceRequirement.advertisingId: AdvertisingIdPermissionFetcher(),
        .userNotification: NotificationPermissionFetcher(),
        OptimoveDeviceRequirement.internet: NetworkCapabilitiesFetcher()
    ]

    static func getInstance(requirement: OptimoveDeviceRequirement) -> Fetchable! {
        return dictionary[requirement]
    }
}
