//  Copyright © 2019 Optimove. All rights reserved.

import Foundation
import OptimoveCore

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
