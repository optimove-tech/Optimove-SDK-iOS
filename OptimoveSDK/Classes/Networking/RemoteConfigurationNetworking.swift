//  Copyright © 2019 Optimove. All rights reserved.

import Foundation
import OptimoveCore

final class RemoteConfigurationNetworking {

    private let networkClient: NetworkClient
    private let requestBuilder: RemoteConfigurationRequestBuilder

    init(networkClient: NetworkClient,
         requestBuilder: RemoteConfigurationRequestBuilder) {
        self.networkClient = networkClient
        self.requestBuilder = requestBuilder
    }

    func getTenantConfiguration(_ completion: @escaping (Result<TenantConfig, Error>) -> Void) {
        do {
            let request = try requestBuilder.createTenantConfigurationsRequest()
            networkClient.perform(request) { (result) in
                completion(
                    Result {
                        return try result.get().decode(to: TenantConfig.self)
                    }
                )
            }
        } catch {
            completion(.failure(error))
        }
    }

    func getGlobalConfiguration(_ completion: @escaping (Result<GlobalConfig, Error>) -> Void) {
        let request = requestBuilder.createGlobalConfigurationsRequest()
        networkClient.perform(request) { (result) in
            completion(
                Result {
                    return try result.get().decode(to: GlobalConfig.self)
                }
            )
        }
    }

}
