//  Copyright © 2019 Optimove. All rights reserved.

final class SetAdvertisingIdEvent: Event {

    struct Constants {
        static let name = OptimoveKeys.Configuration.setAdvertisingId.rawValue
        struct Key {
            static let advertisingId = OptimoveKeys.Configuration.advertisingId.rawValue
            static let deviceId = OptimoveKeys.Configuration.deviceId.rawValue
            static let appNS = OptimoveKeys.Configuration.appNs.rawValue
        }
    }

    init(advertisingId: String, deviceId: String, appNs: String) {
        super.init(
            name: Constants.name,
            context: [
                Constants.Key.advertisingId: advertisingId,
                Constants.Key.deviceId: deviceId,
                Constants.Key.appNS: appNs
            ]
        )
    }
}
