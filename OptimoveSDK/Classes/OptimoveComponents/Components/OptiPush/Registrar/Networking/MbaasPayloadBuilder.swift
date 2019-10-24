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

    func createAddMergeUser() -> AddMergeUser {
        return AddMergeUser(
            deviceID: deviceID,
            appNS: appNamespace,
            os: AddMergeUser.Constants.os,
            pushToken: storage.apnsToken?.map{ String(format: "%02.2hhx", $0) }.joined(),
            optIn: (try? storage.getIsMbaasOptIn()) ?? true
        )
    }

    func createMigrateUser() throws -> MigrateUser {
        return MigrateUser(
            oldID: try storage.getVisitorID(),
            newID: try storage.getCustomerID()
        )
    }
}

struct AddMergeUser: Codable {
    struct Constants {
        static let os = "ios"
    }
    let deviceID, appNS, os: String
    let pushToken: String?
    let optIn: Bool

    enum CodingKeys: String, CodingKey {
        case deviceID = "device_id"
        case appNS = "app_ns"
        case os
        case pushToken = "push_token"
        case optIn = "opt_in"
    }
}

struct MigrateUser: Codable {
    let oldID, newID: String

    enum CodingKeys: String, CodingKey {
        case oldID = "old_id"
        case newID = "new_id"
    }
}
