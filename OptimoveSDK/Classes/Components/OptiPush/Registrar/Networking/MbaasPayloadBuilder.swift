//  Copyright © 2019 Optimove. All rights reserved.

import Foundation
import OptimoveCore

final class MbaasPayloadBuilder {

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
        return SetUser(
            deviceID: deviceID,
            appNS: appNamespace,
            os: SetUser.Constants.os,
            deviceToken: token.map{ String(format: "%02.2hhx", $0) }.joined(),
            optIn: storage.optFlag,
            isDev: try MobileProvision.read().entitlements.apsEnvironment == .development
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

struct SetUser: Codable {

    struct Constants {
        static let os = "ios"
    }

    let deviceID, appNS, os, deviceToken: String
    let optIn, isDev: Bool

    enum CodingKeys: String, CodingKey {
        case deviceID = "device_id"
        case appNS = "app_ns"
        case os
        case deviceToken = "device_token"
        case optIn = "opt_in"
        case isDev = "is_dev"
    }
}

struct AddUserAlias: Codable {

    let newAliases: [String]

    enum CodingKeys: String, CodingKey {
        case newAliases = "new_aliases"
    }
}
