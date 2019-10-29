//  Copyright © 2019 Optimove. All rights reserved.

import Foundation
import OptimoveCore

final class MbaasPayloadBuilder {

    private let storage: OptimoveStorage
    private let deviceID: String
    private let appNamespace: String
    private let tenantID: String

    init(storage: OptimoveStorage,
         deviceID: String,
         appNamespace: String,
         tenantID: String) {
        self.storage = storage
        self.deviceID = deviceID
        self.appNamespace = appNamespace
        self.tenantID = tenantID
    }

    func createSetUser() -> SetUser {
        return SetUser(
            deviceID: deviceID,
            appNS: appNamespace,
            os: SetUser.Constants.os,
            tenantAlias: tenantID,
            deviceToken: storage.apnsToken?.map{ String(format: "%02.2hhx", $0) }.joined(),
            optIn: (try? storage.getIsMbaasOptIn()) ?? true,
            isDev: SDK.isDebugging
        )
    }

    // Alias is a value, like id, that could identifier an object of user/tenant.
    func createAddUserAlias() throws -> AddUserAlias {
        return AddUserAlias(
            tenantAlias: tenantID,
            currentAlias: try storage.getInitialVisitorId(),
            newAlias: try storage.getCustomerID()
        )
    }
}

struct SetUser: Codable {
    struct Constants {
        static let os = "ios"
    }
    let deviceID, appNS, os, tenantAlias: String
    let deviceToken: String?
    let optIn: Bool
    let isDev: Bool

    enum CodingKeys: String, CodingKey {
        case deviceID = "device_id"
        case appNS = "app_ns"
        case os
        case deviceToken = "device_token"
        case optIn = "opt_in"
        case tenantAlias = "tenant_alias"
        case isDev = "is_dev"
    }
}

struct AddUserAlias: Codable {
    let tenantAlias, currentAlias, newAlias: String

    enum CodingKeys: String, CodingKey {
        case tenantAlias = "tenant_alias"
        case currentAlias = "current_alias"
        case newAlias = "new_alias"
    }
}
