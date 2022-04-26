//  Copyright © 2017 Optimove. All rights reserved.

import Foundation
import OptimoveCore

final class SDKInitializer {

    private let componentFactory: ComponentFactory
    private let pipeline: PipelineMutator
    private let dependencies: [SDKInitializerDependency]
    private let storage: OptimoveStorage

    // MARK: - Construction

    init(componentFactory: ComponentFactory,
         pipeline: PipelineMutator,
         dependencies: [SDKInitializerDependency],
         storage: OptimoveStorage) {
        self.componentFactory = componentFactory
        self.pipeline = pipeline
        self.dependencies = dependencies
        self.storage = storage
    }

    func initialize(with configuration: Configuration) {
        dependencies.forEach { $0.onConfigurationFetch(configuration) }
        do {
            try setupOptimoveComponents(configuration)
            Logger.debug("Optimove SDK is initialized.")
        } catch {
            Logger.error("🚨 Optimove SDK failed on initialization. Error: \(error.localizedDescription)")
        }
    }

}

private extension SDKInitializer {

    func setupOptimoveComponents(_ configuration: Configuration) throws {

        // MARK: Setup Eventable chain of responsibility.

        // 1 responder
        let normalizer = ParametersNormalizer(configuration: configuration)

        // 2 responder
        let validator = EventValidator(configuration: configuration, storage: storage)

        // 3 responder
        let decorator = ParametersDecorator(configuration: configuration)

        var optistreamComponents: [OptistreamComponent?] = [
            try componentFactory.createOptitrackComponent(configuration: configuration)
        ]
        if isAllowedToRunRealtimeComponent(configuration) {
            optistreamComponents.append(
                try componentFactory.createRealtimeComponent(configuration: configuration)
            )
        }

        // 4 responder
        let componentHanlder = ComponentHandler(
            commonComponents: [],
            optistreamComponents: optistreamComponents.compactMap { $0 },
            optirstreamEventBuilder: componentFactory.createOptistreamEventBuilder(configuration: configuration)
        )

        decorator.next = componentHanlder
        validator.next = decorator
        normalizer.next = validator

        pipeline.addNextPipe(normalizer)

        Logger.info("All components setup finished.")
    }

    func isAllowedToRunRealtimeComponent(_ configuration: Configuration) -> Bool {
        return configuration.isEnableRealtime && !configuration.realtime.isEnableRealtimeThroughOptistream
    }

}

protocol SDKInitializerDependency {
    func onConfigurationFetch(_ configuration: Configuration)
}

final class OptimoveStrorageSDKInitializerDependency: SDKInitializerDependency {

    private var storage: OptimoveStorage

    init(storage: OptimoveStorage) {
        self.storage = storage
    }

    func onConfigurationFetch(_ configuration: Configuration) {
        storage.siteID = configuration.tenantID
        storage.tenantID = configuration.tenantID
        storage.optitrackEndpoint = configuration.optitrack.optitrackEndpoint
    }
}

final class MultiplexLoggerStreamSDKInitializerDependency: SDKInitializerDependency {

    func onConfigurationFetch(_ configuration: Configuration) {
        MultiplexLoggerStream.mutateStreams(mutator: { (stream) in
            stream.tenantId = configuration.tenantID
            stream.endpoint = configuration.logger.logServiceEndpoint
            stream.isProductionLogsEnabled = configuration.logger.isProductionLogsEnabled
        })
    }

}
