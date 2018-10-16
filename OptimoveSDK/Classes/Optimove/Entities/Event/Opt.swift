

import Foundation
class Opt :OptimoveCoreEvent
{
    var name: String
    {
        return ""
    }
    var parameters: [String : Any]
    {
        return [OptimoveKeys.Configuration.timestamp.rawValue   : Int(Date().timeIntervalSince1970),
                OptimoveKeys.Configuration.appNs.rawValue       : Bundle.main.bundleIdentifier!,
                OptimoveKeys.Configuration.deviceId.rawValue    : DeviceID]
    }
}

class OptipushOptIn: Opt
{
    override var name: String
    {
        return OptimoveKeys.Configuration.optipushOptIn.rawValue
    }
}

class OptipushOptOut: Opt
{
    override var name: String
    {
        return OptimoveKeys.Configuration.optipushOptOut.rawValue
    }
}
