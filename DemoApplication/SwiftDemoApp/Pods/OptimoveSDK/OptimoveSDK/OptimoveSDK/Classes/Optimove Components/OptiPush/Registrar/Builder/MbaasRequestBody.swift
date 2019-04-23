import UIKit

struct MbaasRequestBody: CustomStringConvertible {
    let tenantId: Int
    let deviceId: String
    let appNs: String
    let osVersion: String

    var visitorId: String?
    var publicCustomerId: String?

    var optIn: Bool?

    var token: String?
    let operation: MbaasOperations
    var isConversion: Bool?

    var description: String {
       return  "tenantId=\(tenantId)&deviceId=\(deviceId)&appNs=\(appNs)&osVersion=\(osVersion)&visitorId=\(visitorId ?? "" )&publicCustomerId=\(publicCustomerId ?? "")&optIn=\(optIn?.description ?? "")&token=\(token ?? "")&operation=\(operation)&isConversion=\(isConversion?.description ?? "")"

    }

    init(operation: MbaasOperations) {
        self.operation = operation
        tenantId = TenantID ?? -1
        deviceId = DeviceID
        appNs = Bundle.main.bundleIdentifier?.replacingOccurrences(of: ".", with: "_") ?? ""
        osVersion = ProcessInfo().operatingSystemVersionOnlyString
    }

    func toMbaasJsonBody() -> Data? {
        var requestJsonData = [String: Any]()
        switch operation {
        case .optIn: fallthrough
        case .optOut: fallthrough
        case .unregistration:
            let iOSToken = [OptimoveKeys.Registration.bundleID.rawValue: appNs,
                            OptimoveKeys.Registration.deviceID.rawValue: DeviceID ]
            requestJsonData[OptimoveKeys.Registration.iOSToken.rawValue]    = iOSToken
            requestJsonData[OptimoveKeys.Registration.tenantID.rawValue]    = TenantID
            if let customerId = OptimoveUserDefaults.shared.customerID {
                requestJsonData[OptimoveKeys.Registration.customerID.rawValue] = customerId
            } else {
                requestJsonData[OptimoveKeys.Registration.visitorID.rawValue]   = VisitorID
            }
        case .registration:
            var bundle = [String: Any]()
            bundle[OptimoveKeys.Registration.optIn.rawValue] = OptimoveUserDefaults.shared.isMbaasOptIn
            bundle[OptimoveKeys.Registration.token.rawValue] = OptimoveUserDefaults.shared.fcmToken
            let app = [appNs: bundle]
            var device: [String: Any] = [OptimoveKeys.Registration.apps.rawValue: app]
            device[OptimoveKeys.Registration.osVersion.rawValue] = ProcessInfo().operatingSystemVersionOnlyString
            let ios = [deviceId: device]
            requestJsonData[OptimoveKeys.Registration.iOSToken.rawValue]         = ios
            requestJsonData[OptimoveKeys.Registration.tenantID.rawValue]         = OptimoveUserDefaults.shared.siteID

            if let customerId = OptimoveUserDefaults.shared.customerID {
                requestJsonData[OptimoveKeys.Registration.origVisitorID.rawValue] = OptimoveUserDefaults.shared.initialVisitorId

                requestJsonData[OptimoveKeys.Registration.isConversion.rawValue]    = OptimoveUserDefaults.shared.isFirstConversion
                requestJsonData[OptimoveKeys.Registration.customerID.rawValue]       = customerId
            } else {
                requestJsonData[OptimoveKeys.Registration.visitorID.rawValue]        = OptimoveUserDefaults.shared.visitorID
            }
        }

        let dictionary = [operation.rawValue: requestJsonData]
        return try! JSONSerialization.data(withJSONObject: dictionary, options: [])
    }
}
