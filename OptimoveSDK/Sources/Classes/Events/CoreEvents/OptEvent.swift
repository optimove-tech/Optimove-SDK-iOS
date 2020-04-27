//  Copyright © 2019 Optimove. All rights reserved.

class OptEvent: Event {

    struct Constants {
        static let optInName = OptimoveKeys.Configuration.optipushOptIn.rawValue
        static let optOutName = OptimoveKeys.Configuration.optipushOptOut.rawValue
        struct Key {
            static let timestamp = OptimoveKeys.Configuration.timestamp.rawValue
            static let appNs = OptimoveKeys.Configuration.appNs.rawValue
            static let deviceId = OptimoveKeys.Configuration.deviceId.rawValue
        }
    }

    required init(name: String, timestamp: Double, applicationNameSpace: String, deviceId: String) {
        super.init(
            name: name,
            context: [
                Constants.Key.timestamp: Int(timestamp),
                Constants.Key.appNs: applicationNameSpace,
                Constants.Key.deviceId: deviceId
            ]
        )
    }

}

final class OptipushOptInEvent: OptEvent {

    convenience init(timestamp: Double, applicationNameSpace: String, deviceId: String) {
        self.init(
            name: Constants.optInName,
            timestamp: timestamp,
            applicationNameSpace: applicationNameSpace, deviceId: deviceId)
    }

}

final class OptipushOptOutEvent: OptEvent {

    convenience init(timestamp: Double, applicationNameSpace: String, deviceId: String) {
        self.init(name: Constants.optOutName, timestamp: timestamp, applicationNameSpace: applicationNameSpace, deviceId: deviceId)
    }
}
