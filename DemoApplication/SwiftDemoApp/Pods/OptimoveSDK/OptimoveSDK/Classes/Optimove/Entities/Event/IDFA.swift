

import Foundation
import AdSupport

class SetAdvertisingId : OptimoveCoreEvent
{
    var name: String
    {
        return Keys.Configuration.setAdvertisingId.rawValue
    }
    
    var parameters: [String : Any]
    {
        return [Keys.Configuration.advertisingId.rawValue   : ASIdentifierManager.shared().advertisingIdentifier.uuidString ,
                Keys.Configuration.deviceId.rawValue        : DeviceID,
                Keys.Configuration.appNs.rawValue           : Bundle.main.bundleIdentifier!]
    }
}
