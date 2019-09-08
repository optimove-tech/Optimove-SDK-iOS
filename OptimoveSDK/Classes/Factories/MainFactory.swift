//  Copyright © 2019 Optimove. All rights reserved.

import Foundation

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
        return CoreEventFactoryImpl(
            storage: serviceLocator.storage(),
            dateTimeProvider: serviceLocator.dateTimeProvider()
        )
    }

    func networkingFactory() -> NetworkingFactory {
        return NetworkingFactory(
            networkClient: NetworkClientImpl(),
            requestBuilderFactory: NetworkRequestBuilderFactory(
                serviceLocator: serviceLocator
            )
        )
    }

    func initializer() -> OptimoveSDKInitializer {
        return OptimoveSDKInitializer(
            deviceStateMonitor: serviceLocator.deviceStateMonitor(),
            storage: serviceLocator.storage(),
            networking: networkingFactory().createRemoteConfigurationNetworking(),
            configurationRepository: serviceLocator.configurationRepository(),
            componentFactory: componentFactory(),
            componentsPool: serviceLocator.mutableComponentsPool(),
            handlersPool: serviceLocator.handlersPool()
        )
    }
}
