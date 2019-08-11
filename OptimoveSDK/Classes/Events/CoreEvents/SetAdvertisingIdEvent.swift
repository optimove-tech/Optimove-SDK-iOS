// Copiright 2019 Optimove

final class SetAdvertisingIdEvent: OptimoveCoreEvent {

    struct Constants {
        static let name = OptimoveKeys.Configuration.setAdvertisingId.rawValue
        struct Key {
            static let advertisingId = OptimoveKeys.Configuration.advertisingId.rawValue
            static let deviceId = OptimoveKeys.Configuration.deviceId.rawValue
            static let appNS = OptimoveKeys.Configuration.appNs.rawValue
        }
    }

    let name: String = Constants.name
    let parameters: [String: Any]

    init(advertisingId: String, deviceId: String, appNs: String) {
        parameters = [
            Constants.Key.advertisingId: advertisingId,
            Constants.Key.deviceId: deviceId,
            Constants.Key.appNS: appNs
        ]
    }
}
