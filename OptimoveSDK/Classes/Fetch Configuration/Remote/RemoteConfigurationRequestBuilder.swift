//  Copyright © 2019 Optimove. All rights reserved.

import Foundation

final class RemoteConfigurationRequestBuilder {

    private let storage: OptimoveStorage

    init(storage: OptimoveStorage) {
        self.storage = storage
    }

    func createTenantConfigurationsRequest() throws -> NetworkRequest {
        let tenantToken = try storage.getTenantToken()
        let version = try storage.getVersion()
        let configurationEndPoint = try storage.getConfigurationEndPoint()
        let url = configurationEndPoint
            .appendingPathComponent(tenantToken)
            .appendingPathComponent(version)
            .appendingPathExtension("json")
        OptiLoggerMessages.logPathToRemoteConfiguration(path: url.absoluteString)
        return NetworkRequest(method: .get, baseURL: url)
    }

    func createGlobalConfigurationsRequest() -> NetworkRequest {
        return NetworkRequest(method: .get, baseURL: Endpoints.Remote.globalConfig)
    }

}
