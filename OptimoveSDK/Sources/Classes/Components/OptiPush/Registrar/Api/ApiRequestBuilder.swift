//  Copyright © 2019 Optimove. All rights reserved.

import Foundation
import OptimoveCore

final class ApiRequestBuilder {

    struct Constants {
        static let versionPath = "v3"
        static let tenantsPath = "tenants"
        static let installationPath = "installation"
    }

    private let baseURL: URL

    init(optipushConfig: OptipushConfig) {
        baseURL = optipushConfig.mbaasEndpoint
            .appendingPathComponent(Constants.versionPath)
            .appendingPathComponent(Constants.tenantsPath)
            .appendingPathComponent(String(optipushConfig.tenantID))
            .appendingPathComponent(Constants.installationPath)
    }

    func postSetInstallation(model: Installation) throws -> NetworkRequest {
        return try NetworkRequest(
            method: .post,
            baseURL: baseURL,
            body: model,
            keyEncodingStrategy: .convertToSnakeCase
        )
    }

}
