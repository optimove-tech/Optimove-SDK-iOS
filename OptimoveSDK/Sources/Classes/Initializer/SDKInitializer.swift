//  Copyright © 2017 Optimove. All rights reserved.

import Foundation
import OptimoveCore

final class SDKInitializer {

    private let componentFactory: ComponentFactory
    private let chain: ChainMutator
    private let dependencies: [SDKInitializerDependency]

    // MARK: - Construction

    init(componentFactory: ComponentFactory,
         chainMutator: ChainMutator,
         dependencies: [SDKInitializerDependency]) {
        self.componentFactory = componentFactory
        self.chain = chainMutator
        self.dependencies = dependencies
    }

    func initialize(with configuration: Configuration) {
        dependencies.forEach { $0.onConfigurationFetch(configuration) }
        setupOptimoveComponents(configuration)
        Logger.debug("SDK is initialized.")
    }

}

private extension SDKInitializer {

    func setupOptimoveComponents(_ configuration: Configuration) {

        // MARK: Setup Eventable chain of responsibility.

        // 1 responder
        let normalizer = ParametersNormalizer(configuration: configuration)

        // 2 responder
        let validator = EventValidator(configuration: configuration)

        // 3 responder
        let decorator = ParametersDecorator(configuration: configuration)

        // 4 responder
        let componentHanlder = ComponentHandler(
            components: [
                componentFactory.createOptitrackComponent(configuration: configuration),
                componentFactory.createRealtimeComponent(configuration: configuration),
                componentFactory.createOptipushComponent(configuration: configuration)
            ]
        )

        decorator.next = componentHanlder
        validator.next = decorator
        normalizer.next = validator

        chain.addNode(normalizer)

        Logger.info("All components setup finished.")
    }

}

protocol SDKInitializerDependency {
    func onConfigurationFetch(_ configuration: Configuration)
}

final class OptimoveStrorageSDKInitializerDependency: SDKInitializerDependency {

    private let storage: OptimoveStorage

    init(storage: OptimoveStorage) {
        self.storage = storage
    }

    func onConfigurationFetch(_ configuration: Configuration) {
        storage.set(value: configuration.tenantID, key: .siteID)
    }
}

final class MultiplexLoggerStreamSDKInitializerDependency: SDKInitializerDependency {

    func onConfigurationFetch(_ configuration: Configuration) {
        MultiplexLoggerStream.mutateStreams(mutator: { (stream) in
            stream.tenantId = configuration.tenantID
            stream.endpoint = configuration.logger.logServiceEndpoint
        })
    }

}

final class AirshipServiceSDKInitializerDependency: SDKInitializerDependency {

    private let storage: OptimoveStorage

    init(storage: OptimoveStorage) {
        self.storage = storage
    }

    func onConfigurationFetch(_ configuration: Configuration) {
        tryCatch {
            try OptimoveAirshipIntegration(storage: storage, configuration: configuration).obtain()
        }
    }
}
