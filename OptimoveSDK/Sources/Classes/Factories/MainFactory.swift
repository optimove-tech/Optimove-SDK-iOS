//  Copyright © 2019 Optimove. All rights reserved.

import Foundation
import OptimoveCore

typealias NetworkClient = OptimoveCore.NetworkClient
typealias NetworkClientImpl = OptimoveCore.NetworkClientImpl

final class MainFactory {

    private let serviceLocator: ServiceLocator

    init(serviceLocator: ServiceLocator) {
        self.serviceLocator = serviceLocator
    }

    func componentFactory() -> ComponentFactory {
        return ComponentFactory(
            serviceLocator: serviceLocator,
            coreEventFactory: coreEventFactory()
        )
    }

    func coreEventFactory() -> CoreEventFactory {
        return serviceLocator.coreEventFactory()
    }

    func networkingFactory() -> NetworkingFactory {
        return NetworkingFactory(
            networkClient: NetworkClientImpl(),
            requestBuilderFactory: NetworkRequestBuilderFactory(
                serviceLocator: serviceLocator
            )
        )
    }

    func operationFactory() -> OperationFactory {
        return OperationFactory(
            configurationRepository: serviceLocator.configurationRepository(),
            networking: networkingFactory().createRemoteConfigurationNetworking()
        )
    }

}
