import Foundation

final class RemoteConfigurationHandler {

    private let networking: RemoteConfigurationNetworking

    init(networking: RemoteConfigurationNetworking) {
        self.networking = networking
    }

    func get(completion: @escaping (Result<TenantConfig, Error>) -> Void) {
        networking.downloadConfigurations(completion)
    }
}

final class RemoteConfigurationRequestBuilder {

    private let storage: OptimoveStorage

    init(storage: OptimoveStorage) {
        self.storage = storage
    }

    func createDownloadConfigurationsRequest() throws -> NetworkRequest {
        let tenantToken = try storage.getTenantToken()
        let version = try storage.getVersion()
        let configurationEndPoint = try storage.getConfigurationEndPoint()
        let url: URL = try cast(URL(string: configurationEndPoint + tenantToken))
        OptiLoggerMessages.logPathToRemoteConfiguration(path: url.absoluteString)
        return NetworkRequest(method: .get, baseURL: url, path: "\(version).json")
    }

}


final class RemoteConfigurationNetworking {

    private let networkClient: NetworkClient
    private let requestBuilder: RemoteConfigurationRequestBuilder

    init(networkClient: NetworkClient,
         requestBuilder: RemoteConfigurationRequestBuilder) {
        self.networkClient = networkClient
        self.requestBuilder = requestBuilder
    }

    func downloadConfigurations(_ completion: @escaping (Result<TenantConfig, Error>) -> Void) {
        do {
            let request = try requestBuilder.createDownloadConfigurationsRequest()
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

}
