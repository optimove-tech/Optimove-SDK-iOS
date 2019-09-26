//  Copyright © 2019 Optimove. All rights reserved.

import Foundation
import OptimoveCore

struct AddOrUpdateUserPayload: Codable {
    struct Constants {
        static let os = "ios"
    }
    let deviceID: String
    let appNS: String
    let os: String = Constants.os
    let pushToken: String?
    let optIn: Bool?
}

struct MigrateUserPayload: Codable {
    let oldID: String
    let newID: String
}


final class MbaasPayloadBuilder {

    private let storage: OptimoveStorage
    private let device: SDKDevice.Type
    private let bundle: Bundle.Type

    init(storage: OptimoveStorage,
         device: SDKDevice.Type,
         bundle: Bundle.Type) {
        self.storage = storage
        self.device = device
        self.bundle = bundle
    }

    func createAddOrUpdateUserPayload() throws -> AddOrUpdateUserPayload {
        return AddOrUpdateUserPayload(
            deviceID: device.uuid,
            appNS: try bundle.getApplicationNameSpace().setAsMongoKey(),
            pushToken: storage.apnsToken?.map{ String(format: "%02.2hhx", $0) }.joined(),
            optIn: (try? storage.getIsMbaasOptIn()) ?? true
        )
    }

    func createMigrateUserPayload() throws -> MigrateUserPayload {
        return MigrateUserPayload(
            oldID: try storage.getVisitorID(),
            newID: try storage.getCustomerID()
        )
    }
}
