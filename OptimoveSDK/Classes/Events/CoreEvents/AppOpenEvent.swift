// Copiright 2019 Optimove

final class AppOpenEvent: OptimoveCoreEvent {
    
    struct Constants {
        static let name = "app_open"
        struct Key {
            static let bundleIdentifier = OptimoveKeys.Configuration.appNs.rawValue
            static let deviceID = OptimoveKeys.Configuration.deviceId.rawValue
            static let visitorId = OptimoveKeys.Configuration.visitorId.rawValue
            static let customerId = OptimoveKeys.Configuration.userId.rawValue
        }
    }
    
    let name: String = Constants.name
    let parameters: [String : Any]

    init(bundleIdentifier: String, deviceID: String, visitorID: String?, customerID: String?) {
        var parameters = [
            Constants.Key.bundleIdentifier: bundleIdentifier,
            Constants.Key.deviceID: deviceID
        ]
        if let customerID = customerID {
            parameters[Constants.Key.customerId] = customerID
        } else if let visitorID = visitorID {
            parameters[Constants.Key.visitorId] = visitorID
        }
        self.parameters = parameters
    }
}
