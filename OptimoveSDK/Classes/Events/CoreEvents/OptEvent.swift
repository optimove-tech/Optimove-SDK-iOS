// Copiright 2019 Optimove

class OptEvent: OptimoveCoreEvent {

    struct Constants {
        static let optInName = OptimoveKeys.Configuration.optipushOptIn.rawValue
        static let optOutName = OptimoveKeys.Configuration.optipushOptOut.rawValue
        struct Key {
            static let timestamp = OptimoveKeys.Configuration.timestamp.rawValue
            static let appNs = OptimoveKeys.Configuration.appNs.rawValue
            static let deviceId = OptimoveKeys.Configuration.deviceId.rawValue
        }
    }

    var name: String { fatalError("An implementation provides by inheritance.") }
    let parameters: [String: Any]

    required init(timestamp: Double, applicationNameSpace: String, deviceId: String) {
        parameters = [
            Constants.Key.timestamp: Int(timestamp),
            Constants.Key.appNs: applicationNameSpace,
            Constants.Key.deviceId: deviceId
        ]
    }

}

final class OptipushOptInEvent: OptEvent {
    override var name: String {
        return Constants.optInName
    }
}

final class OptipushOptOutEvent: OptEvent {
    override var name: String {
        return Constants.optOutName
    }
}
