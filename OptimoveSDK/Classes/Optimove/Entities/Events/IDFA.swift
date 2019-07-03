import AdSupport
import Foundation

class SetAdvertisingId: OptimoveCoreEvent {
    var name: String {
        return OptimoveKeys.Configuration.setAdvertisingId.rawValue
    }

    var parameters: [String: Any]

    init() {
        let parameters = [
            OptimoveKeys.Configuration.advertisingId.rawValue:
                ASIdentifierManager.shared().advertisingIdentifier.uuidString,
            OptimoveKeys.Configuration.deviceId.rawValue: DeviceID,
            OptimoveKeys.Configuration.appNs.rawValue: Bundle.main.bundleIdentifier!
        ]
        self.parameters = parameters
    }
}
