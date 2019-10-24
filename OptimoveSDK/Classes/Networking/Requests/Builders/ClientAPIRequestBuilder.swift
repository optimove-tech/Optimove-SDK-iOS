//  Copyright © 2019 Optimove. All rights reserved.

import Foundation
import OptimoveCore

final class ClientAPIRequestBuilder {

    struct Constants {
        static let path = "users"
    }

    private let optipushConfig: OptipushConfig

    init(optipushConfig: OptipushConfig) {
        self.optipushConfig = optipushConfig
    }

    func postAddMergeUser(userID: String, userDevice: AddMergeUser) throws -> NetworkRequest {
        return try NetworkRequest(
            method: .post,
            baseURL: optipushConfig.mbaasEndpoint
                .appendingPathComponent(Constants.path)
                .appendingPathComponent(userID),
            body: userDevice
        )
}

    func putMigrateUser(_ model: MigrateUser) throws -> NetworkRequest {
        return try NetworkRequest(
            method: .put,
            baseURL: optipushConfig.mbaasEndpoint.appendingPathComponent(Constants.path),
            body: model
        )
    }

}
