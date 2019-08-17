//  Copyright © 2019 Optimove. All rights reserved.

import Foundation
import OptimoveCore

/// Used only for `MbaasOperation` cases:
/// - `optIn`
/// - `optOut`
/// - `unregister`
final class MbaasModel: BaseMbaasModel {

    let deviceId: String
    let appNs: String

    init(deviceId: String,
         appNs: String,
         operation: MbaasOperation,
         tenantId: Int,
         userIdPayload: BaseMbaasModel.UserIdPayload) {
        self.deviceId = deviceId
        self.appNs = appNs
        super.init(operation: operation, tenantId: tenantId, userIdPayload: userIdPayload)
    }

    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: RuntimeCodingKey.self)

        /// Assume that each data should contain only one operation.
        let operationKey = try unwrap(
            MbaasOperation.allCases
                .compactMap { RuntimeCodingKey(stringValue: $0.rawValue) }
                .filter { container.contains($0) }
                .first
            )
        let operationContainer = try container.nestedContainer(keyedBy: OptimoveKeys.Registration.self,
                                                               forKey: operationKey)

        let iosContainer = try operationContainer.nestedContainer(keyedBy: OptimoveKeys.Registration.self,
                                                                  forKey: .iosToken)
        deviceId = try iosContainer.decode(String.self, forKey: .deviceID)
        appNs = try iosContainer.decode(String.self, forKey: .bundleID)

        super.init(
            operation: try unwrap(MbaasOperation(rawValue: operationKey.stringValue)),
            tenantId: try operationContainer.decode(Int.self, forKey: .tenantID),
            userIdPayload: try BaseMbaasModel.UserIdPayload(from: operationContainer)
        )
    }

    override func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: RuntimeCodingKey.self)

        let operationKey: RuntimeCodingKey = try cast(RuntimeCodingKey(stringValue: operation.rawValue))
        var operationContainer = container.nestedContainer(keyedBy: OptimoveKeys.Registration.self, forKey: operationKey)

        var iosContatiner = operationContainer.nestedContainer(keyedBy: OptimoveKeys.Registration.self, forKey: .iosToken)

        try iosContatiner.encode(appNs, forKey: .bundleID)
        try iosContatiner.encode(deviceId, forKey: .deviceID)

        try operationContainer.encode(tenantId, forKey: .tenantID)
        try userIdPayload.encode(to: &operationContainer)
    }

    static func == (lhs: MbaasModel, rhs: MbaasModel) -> Bool {
        return lhs.operation == rhs.operation &&
            lhs.tenantId == rhs.tenantId &&
            lhs.userIdPayload == rhs.userIdPayload &&
            lhs.deviceId == rhs.deviceId &&
            lhs.appNs == rhs.appNs
    }
}
