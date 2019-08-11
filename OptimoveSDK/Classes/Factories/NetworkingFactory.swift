// Copiright 2019 Optimove

import Foundation

/// Create network request builders.
final class NetworkRequestBuilderFactory {

    private let serviceLocator: ServiceLocator

    init(serviceLocator: ServiceLocator) {
        self.serviceLocator = serviceLocator
    }

    func createRemoteConfigurationRequestBuiler() -> RemoteConfigurationRequestBuilder {
        return RemoteConfigurationRequestBuilder(storage: serviceLocator.storage())
    }

}
