//  Copyright © 2017 Optimove. All rights reserved.

import Foundation
import OptimoveCore

final class SDKInitializer {

    private let storage: OptimoveStorage
    private let componentFactory: ComponentFactory
    private let chain: ChainMutator

    // MARK: - Construction

    init(storage: OptimoveStorage,
         componentFactory: ComponentFactory,
         chainMutator: ChainMutator) {
        self.storage = storage
        self.componentFactory = componentFactory
        self.chain = chainMutator
    }

    func initialize(with configuration: Configuration) {
        updateEnvironment(configuration)
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
                componentFactory.createOptipushComponent(configuration: configuration)
            ]
        )

        decorator.next = componentHanlder
        validator.next = decorator
        normalizer.next = validator

        chain.addNode(normalizer)

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
