// Copiright 2019 Optimove

final class AppOpenEvent: OptimoveCoreEvent {
    
    struct Constants {
        static let name = "app_open"
        struct Key {
            static let appNS = OptimoveKeys.Configuration.appNs.rawValue
            static let deviceID = OptimoveKeys.Configuration.deviceId.rawValue
            static let visitorID = OptimoveKeys.Configuration.visitorId.rawValue
            static let userID = OptimoveKeys.Configuration.userId.rawValue
        }
    }
    
    let name: String = Constants.name
    let parameters: [String : Any]

    init(bundleIdentifier: String, deviceID: String, visitorID: String?, customerID: String?) {
        var parameters = [
            Constants.Key.appNS: bundleIdentifier,
            Constants.Key.deviceID: deviceID
        ]
        if let customerID = customerID {
            parameters[Constants.Key.userID] = customerID
        } else if let visitorID = visitorID {
            parameters[Constants.Key.visitorID] = visitorID
        }
        self.parameters = parameters
    }
}
