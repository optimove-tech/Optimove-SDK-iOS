//  Copyright © 2017 Optimove. All rights reserved.

import Foundation
import OptimoveCore

final class OptimoveSDKInitializer {

    private let storage: OptimoveStorage
    private let componentFactory: ComponentFactory
    private let components: MutableComponentsPool
    private let handlersPool: HandlersPool

    // MARK: - Construction

    init(storage: OptimoveStorage,
         componentFactory: ComponentFactory,
         componentsPool: MutableComponentsPool,
         handlersPool: HandlersPool) {
        self.storage = storage
        self.componentFactory = componentFactory
        self.components = componentsPool
        self.handlersPool = handlersPool
    }

    func initialize(with configuration: Configuration) {
        updateEnvironment(configuration)
        setupOptimoveComponents(configuration)
        Logger.debug("SDK is initialized.")
    }

}

private extension OptimoveSDKInitializer {

    func setupOptimoveComponents(_ configuration: Configuration) {

        // MARK: Setup Eventable chain of responsibility.
        components.addComponent(componentFactory.createOptitrackComponent(configuration: configuration))
        components.addComponent(componentFactory.createRealtimeComponent(configuration: configuration))

        // 1
        let normalizer = ParametersNormalizer(configuration: configuration)

        // 2
        let decorator = ParametersDecorator(configuration: configuration)

        // 3
        let componentHanlder = ComponentEventableHandler(component: components)

        normalizer.next = decorator
        decorator.next = componentHanlder

        handlersPool.addNextEventableHandler(normalizer)

        // MARK: Setup Pushable chain of responsibility.
        components.addComponent(componentFactory.createOptipushComponent(configuration: configuration))
        handlersPool.addNextPushableHandler(ComponentPushableHandler(component: components))

        Logger.info("All components setup finished.")
    }

    func updateEnvironment(_ config: Configuration) {
        updateLoggerStreamContainers(config)
        storage.set(value: config.tenantID, key: .siteID)
    }

    func updateLoggerStreamContainers(_ config: Configuration) {
        MultiplexLoggerStream.mutateStreams(mutator: { (stream) in
            stream.tenantId = config.tenantID
            stream.endpoint = config.logger.logServiceEndpoint
        })
    }
}
