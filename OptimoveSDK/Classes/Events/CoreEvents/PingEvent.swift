//  Copyright © 2019 Optimove. All rights reserved.

final class PingEvent: OptimoveCoreEvent {

    struct Constants {
        static let name = "notification_ping"
        struct Key {
            static let appNs = OptimoveKeys.Configuration.appNs.rawValue
            static let deviceId = OptimoveKeys.Configuration.deviceId.rawValue
            static let visitorId = OptimoveKeys.Configuration.visitorId.rawValue
        }
    }
    
    let name: String = Constants.name
    let parameters: [String: Any]

    init(visitorId: String, deviceId: String, appNs: String) {
        parameters = [
            Constants.Key.visitorId: visitorId,
            Constants.Key.deviceId: deviceId,
            Constants.Key.appNs: appNs
        ]
    }

}
