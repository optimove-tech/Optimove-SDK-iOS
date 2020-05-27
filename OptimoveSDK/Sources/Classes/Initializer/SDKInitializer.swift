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
        do {
            try setupOptimoveComponents(configuration)
            Logger.debug("SDK is initialized.")
        } catch {
            Logger.error("🚨 SDK failed on initialization. Error: \(error.localizedDescription)")
        }
    }

}

private extension SDKInitializer {

    func setupOptimoveComponents(_ configuration: Configuration) throws {

        // MARK: Setup Eventable chain of responsibility.

        // 1 responder
        let normalizer = ParametersNormalizer(configuration: configuration)

        // 2 responder
        let validator = EventValidator(configuration: configuration)

        // 3 responder
        let decorator = ParametersDecorator(configuration: configuration)

        var optistreamComponents: [OptistreamComponent?] = [
            try componentFactory.createOptitrackComponent(configuration: configuration)
        ]
        if configuration.isEnableRealtime {
            optistreamComponents.append(
                try componentFactory.createRealtimeComponent(configuration: configuration)
            )
        }

        // 4 responder
        let componentHanlder = ComponentHandler(
            commonComponents: [
                componentFactory.createOptipushComponent(configuration: configuration)
            ],
            optistreamComponents: optistreamComponents.compactMap { $0 },
            optirstreamEventBuilder: componentFactory.createOptistreamEventBuilder(configuration: configuration)
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
