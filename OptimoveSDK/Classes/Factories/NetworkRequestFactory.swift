// Copiright 2019 Optimove

import Foundation

// For creating concrete networking.
final class NetworkingFactory {

    private let networkClient: NetworkClient
    private let requestBuilderFactory: NetworkRequestBuilderFactory

    init(networkClient: NetworkClient,
         requestBuilderFactory: NetworkRequestBuilderFactory) {
        self.networkClient = networkClient
        self.requestBuilderFactory = requestBuilderFactory
    }


    func createRemoteConfigurationNetworking() -> RemoteConfigurationNetworking {
        return RemoteConfigurationNetworking(
            networkClient: networkClient,
            requestBuilder: requestBuilderFactory.createRemoteConfigurationRequestBuiler()
        )
    }
}
