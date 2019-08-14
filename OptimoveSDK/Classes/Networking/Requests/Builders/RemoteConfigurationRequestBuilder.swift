//  Copyright © 2019 Optimove. All rights reserved.

import Foundation
import OptimoveCore

public final class RemoteConfigurationRequestBuilder {

    private let storage: OptimoveStorage

    public init(storage: OptimoveStorage) {
        self.storage = storage
    }

    public func createTenantConfigurationsRequest() throws -> NetworkRequest {
        let tenantToken = try storage.getTenantToken()
        let version = try storage.getVersion()
        let configurationEndPoint = Endpoints.Remote.TenantConfig.url
        let url = configurationEndPoint
            .appendingPathComponent(tenantToken)
            .appendingPathComponent(version)
            .appendingPathExtension("json")
        OptiLoggerMessages.logPathToRemoteConfiguration(path: url.absoluteString)
        return NetworkRequest(method: .get, baseURL: url)
    }

    public func createGlobalConfigurationsRequest() -> NetworkRequest {
        return NetworkRequest(method: .get, baseURL: Endpoints.Remote.GlobalConfig.url(.prod))
    }

}
