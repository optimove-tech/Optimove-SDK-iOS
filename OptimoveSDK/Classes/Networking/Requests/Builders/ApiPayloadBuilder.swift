//  Copyright © 2019 Optimove. All rights reserved.

import Foundation
import OptimoveCore

final class ApiPayloadBuilder {

    private let storage: OptimoveStorage
    private let deviceID: String
    private let appNamespace: String

    init(storage: OptimoveStorage,
         deviceID: String,
         appNamespace: String) {
        self.storage = storage
        self.deviceID = deviceID
        self.appNamespace = appNamespace
    }

    func createSetUser() throws -> SetUser {
        let token = try storage.getApnsToken()
        let tokenToStringFormat = "%02.2hhx"
        return SetUser(
            deviceID: deviceID,
            appNS: appNamespace,
            os: SetUser.Constants.os,
            deviceToken: token.map { String(format: tokenToStringFormat, $0) }.joined(),
            optIn: storage.optFlag,
            isDev: AppEnvironment.isSandboxAps
        )
    }

    // Alias is a value, like id, that could identifier an object of user/tenant.
    func createAddUserAlias() throws -> AddUserAlias {
        let customerID = try storage.getCustomerID()
        let customerIDs = Set<String>([customerID]).union(storage.failedCustomerIDs)
        return AddUserAlias(
            newAliases: Array(customerIDs)
        )
    }
}
