// Copiright 2019 Optimove

import Foundation

/// Used only for `MbaasOperation.registration`
final class RegistartionMbaasModel: BaseMbaasModel {

    let isMbaasOptIn: Bool
    let fcmToken: String
    let osVersion: String
    let deviceId: String
    let appNs: String

    init(isMbaasOptIn: Bool,
         fcmToken: String,
         osVersion: String,
         tenantId: Int,
         userIdPayload: BaseMbaasModel.UserIdPayload,
         deviceId: String,
         appNs: String) {
        self.isMbaasOptIn = isMbaasOptIn
        self.fcmToken = fcmToken
        self.osVersion = osVersion
        self.deviceId = deviceId
        self.appNs = appNs
        super.init(operation: .registration,
                   tenantId: tenantId,
                   userIdPayload: userIdPayload)
    }

    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy:  RuntimeCodingKey.self)

        /// Assume that each data should contain only one operation.
        let operationKey = try unwrap(RuntimeCodingKey(stringValue: MbaasOperation.registration.rawValue))
        let operationContainer = try container.nestedContainer(keyedBy: OptimoveKeys.Registration.self, forKey: operationKey)

        let iosContainer = try operationContainer.nestedContainer(keyedBy: RuntimeCodingKey.self, forKey: .iosToken)

        /// Assume that each data should contain only one iOS container.
        let deviceKey = try cast(iosContainer.allKeys.first) as RuntimeCodingKey
        let deviceContainer = try iosContainer.nestedContainer(keyedBy: OptimoveKeys.Registration.self, forKey: deviceKey)

        osVersion = try deviceContainer.decode(String.self, forKey: .osVersion)

        let appsContainer = try deviceContainer.nestedContainer(keyedBy: RuntimeCodingKey.self, forKey: .apps)

        /// Assume that each data should contain only one application namespace container.
        let appNsKey = try cast(appsContainer.allKeys.first) as RuntimeCodingKey
        let appNsContainer = try appsContainer.nestedContainer(keyedBy: OptimoveKeys.Registration.self, forKey: appNsKey)

        isMbaasOptIn = try appNsContainer.decode(Bool.self, forKey: .optIn)
        fcmToken = try appNsContainer.decode(String.self, forKey: .token)
        deviceId = deviceKey.stringValue
        appNs = appNsKey.stringValue

        super.init(
            operation: .registration,
            tenantId: try operationContainer.decode(Int.self, forKey: .tenantID),
            userIdPayload: try BaseMbaasModel.UserIdPayload(from: operationContainer)
        )
    }

    override func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: RuntimeCodingKey.self)

        let operationKey = try unwrap(RuntimeCodingKey(stringValue: operation.rawValue))
        var operationContainer = container.nestedContainer(keyedBy: OptimoveKeys.Registration.self, forKey: operationKey)

        var iosContatiner = operationContainer.nestedContainer(keyedBy: RuntimeCodingKey.self, forKey: .iosToken)

        let deviceKey = try unwrap(RuntimeCodingKey(stringValue: deviceId))
        var deviceContainer = iosContatiner.nestedContainer(keyedBy: OptimoveKeys.Registration.self, forKey: deviceKey)

        try deviceContainer.encode(osVersion, forKey: .osVersion)

        var appsContainer = deviceContainer.nestedContainer(keyedBy: RuntimeCodingKey.self, forKey: .apps)

        let appNsKey = try unwrap(RuntimeCodingKey(stringValue: appNs))
        var appNsContainer = appsContainer.nestedContainer(keyedBy: OptimoveKeys.Registration.self, forKey: appNsKey)

        try appNsContainer.encode(isMbaasOptIn, forKey: .optIn)
        try appNsContainer.encode(fcmToken, forKey: .token)

        try operationContainer.encode(tenantId, forKey: .tenantID)
        try userIdPayload.encode(to: &operationContainer)
    }

    static func == (lhs: RegistartionMbaasModel, rhs: RegistartionMbaasModel) -> Bool {
        return lhs.operation == rhs.operation &&
            lhs.tenantId == rhs.tenantId &&
            lhs.userIdPayload == rhs.userIdPayload &&
            lhs.isMbaasOptIn == rhs.isMbaasOptIn &&
            lhs.fcmToken == rhs.fcmToken &&
            lhs.osVersion == rhs.osVersion &&
            lhs.deviceId == rhs.deviceId &&
            lhs.appNs == rhs.appNs
    }
}
