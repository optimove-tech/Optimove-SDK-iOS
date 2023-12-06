//  Copyright © 2019 Optimove. All rights reserved.

import Foundation
import OptimoveCore

public final class RemoteConfigurationRequestBuilder {
    enum Error: LocalizedError {
        case failedToCreateTenantConfigurationRequest(Swift.Error)

        var errorDescription: String? {
            switch self {
            case let .failedToCreateTenantConfigurationRequest(error):
                return "Failed to create tenant configuration request: \(error.localizedDescription)"
            }
        }
    }

    private enum Constants {
        static let timeout: TimeInterval = 30
    }

    private let storage: OptimoveStorage

    public init(storage: OptimoveStorage) {
        self.storage = storage
    }

    public func createTenantConfigurationsRequest() throws -> NetworkRequest {
        do {
            let tenantToken = try storage.getTenantToken()
            let version = try storage.getVersion()
            let configurationEndPoint = Endpoints.Remote.TenantConfig.url
            let url = configurationEndPoint
                .appendingPathComponent(tenantToken)
                .appendingPathComponent(version)
                .appendingPathExtension("json")
            Logger.debug("Connect to \(url.absoluteString) to retreive configuration file.")
            return NetworkRequest(method: .get, baseURL: url, timeoutInterval: Constants.timeout)
        } catch {
            throw Error.failedToCreateTenantConfigurationRequest(error)
        }
    }

    public func createGlobalConfigurationsRequest() -> NetworkRequest {
        let url = Endpoints.Remote.GlobalConfig.url
        Logger.debug("Connect to \(url.absoluteString) to retreive global file.")
        return NetworkRequest(method: .get, baseURL: url, timeoutInterval: Constants.timeout)
    }
}
