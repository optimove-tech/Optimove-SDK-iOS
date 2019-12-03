//  Copyright © 2019 Optimove. All rights reserved.

import Foundation
import OptimoveCore

final class ClientAPIRequestBuilder {

    struct Constants {
        static let tenantsPath = "tenants"
        static let usersPath = "users"
    }

    private let optipushConfig: OptipushConfig

    init(optipushConfig: OptipushConfig) {
        self.optipushConfig = optipushConfig
    }

    func postAddMergeUser(userID: String, model: SetUser) throws -> NetworkRequest {
        return try NetworkRequest(
            method: .post,
            baseURL: optipushConfig.mbaasEndpoint
                .appendingPathComponent(Constants.tenantsPath)
                .appendingPathComponent(String(optipushConfig.tenantID))
                .appendingPathComponent(Constants.usersPath)
                .appendingPathComponent(userID),
            body: model
        )
    }

    func putMigrateUser(userID: String, model: AddUserAlias) throws -> NetworkRequest {
        return try NetworkRequest(
            method: .put,
            baseURL: optipushConfig.mbaasEndpoint
                .appendingPathComponent(Constants.tenantsPath)
                .appendingPathComponent(String(optipushConfig.tenantID))
                .appendingPathComponent(Constants.usersPath)
                .appendingPathComponent(userID),
            body: model
        )
    }

}
