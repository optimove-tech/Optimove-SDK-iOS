//  Copyright © 2019 Optimove. All rights reserved.

final class AppOpenEvent: Event {
    enum Constants {
        static let name = "app_open"
        enum Key {
            static let appNS = OptimoveKeys.Configuration.appNs.rawValue
            static let deviceID = OptimoveKeys.Configuration.deviceId.rawValue
            static let visitorID = OptimoveKeys.Configuration.visitorId.rawValue
            static let userID = OptimoveKeys.Configuration.userId.rawValue
        }
    }

    init(bundleIdentifier: String, deviceID: String, visitorID: String?, customerID: String?) {
        var parameters = [
            Constants.Key.appNS: bundleIdentifier,
            Constants.Key.deviceID: deviceID,
        ]
        if let customerID = customerID {
            parameters[Constants.Key.userID] = customerID
        } else if let visitorID = visitorID {
            parameters[Constants.Key.visitorID] = visitorID
        }
        super.init(name: Constants.name, context: parameters)
    }
}
