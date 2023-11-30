//  Copyright © 2019 Optimove. All rights reserved.

import Foundation
import OptimoveCore

public final class RemoteConfigurationRequestBuilder {
    private enum Constants {
        static let timeout: TimeInterval = 30
    }

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
        Logger.debug("Connect to \(url.absoluteString) to retreive configuration file.")
        return NetworkRequest(method: .get, baseURL: url, timeoutInterval: Constants.timeout)
    }

    public func createGlobalConfigurationsRequest() -> NetworkRequest {
        let url = Endpoints.Remote.GlobalConfig.url
        Logger.debug("Connect to \(url.absoluteString) to retreive global file.")
        return NetworkRequest(method: .get, baseURL: url, timeoutInterval: Constants.timeout)
    }
}
