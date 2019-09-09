//  Copyright © 2017 Optimove. All rights reserved.

import Foundation
import OptimoveCore

final class OptimoveSDKInitializer {

    private let deviceStateMonitor: OptimoveDeviceStateMonitor
    private let storage: OptimoveStorage
    private let networking: RemoteConfigurationNetworking
    private let configurationRepository: ConfigurationRepository
    private let componentFactory: ComponentFactory
    private let components: MutableComponentsPool
    private let handlersPool: HandlersPool

    private lazy var operationQueue: OperationQueue = {
        let queue = OperationQueue()
        queue.qualityOfService = .userInitiated
        return queue
    }()

    // MARK: - Construction

    init(deviceStateMonitor: OptimoveDeviceStateMonitor,
         storage: OptimoveStorage,
         networking: RemoteConfigurationNetworking,
         configurationRepository: ConfigurationRepository,
         componentFactory: ComponentFactory,
         componentsPool: MutableComponentsPool,
         handlersPool: HandlersPool) {
        self.deviceStateMonitor = deviceStateMonitor
        self.storage = storage
        self.networking = networking
        self.configurationRepository = configurationRepository
        self.componentFactory = componentFactory
        self.components = componentsPool
        self.handlersPool = handlersPool
    }

    // MARK: - API

    func initialize(completion: @escaping (Result<Void, Error>) -> Void) {
        Logger.debug("Initialization started.")
        handleFetchConfigurationFromRemote { (result) in
            switch result {
            case .success:
                Logger.info("Initialization finished. ✅")
            case let .failure(error):
                Logger.error(error.localizedDescription)
                Logger.error("Initialization failed. 🛑")
            }
            completion(result)
        }
    }

}

private extension OptimoveSDKInitializer {

    func handleFetchConfigurationFromRemote(completion: @escaping (Result<Void, Error>) -> Void) {
        // Operations that execute asynchronously to fetch remote configs.
        let downloadOperations: [Operation] = [
            GlobalConfigurationDownloader(
                networking: networking,
                repository: configurationRepository
            ),
            TenantConfigurationDownloader(
                networking: networking,
                repository: configurationRepository
            )
        ]

        // Operation merge all remote configs to a invariant.
        let mergeOperation = MergeRemoteConfigurationOperation(
            repository: configurationRepository
        )

        // Set the merge operation as dependent on the download operations.
        downloadOperations.forEach {
            mergeOperation.addDependency($0)
        }

        // Set the completion operation for aline two asynchronous operations together.
        let completionOperation = BlockOperation {
            // If there no configuration file either downloaded or stored, the SDK cannot be initialized.
            completion(
                Result(catching: {
                    let configuration = try self.configurationRepository.getConfiguration()
                    self.finishInitialization(configuration)
                })
            )
        }

        // Combine the operations for an executing
        let operations = downloadOperations + [mergeOperation]
        operations.forEach {
            // Set the completion operation as dependent for all operations before they start executing.
            completionOperation.addDependency($0)
            operationQueue.addOperation($0)
        }
        // The completion operation is performing on the current queue.
        operationQueue.addOperation(completionOperation)
    }

    func finishInitialization(_ configuration: Configuration) {
        updateEnvironment(configuration)
        setupOptimoveComponents(configuration)
    }

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

}

extension OptimoveSDKInitializer {

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

final class ParametersNormalizer: EventableHandler {

    private let configuration: Configuration

    init(configuration: Configuration) {
        self.configuration = configuration
    }

    // MARK: - EventableHandler

    override func handle(_ context: EventableOperationContext) throws {
        let normilizeFunction = { [configuration] () -> EventableOperationContext in
            switch context.operation {
            case let .report(event: event):
                return EventableOperationContext(
                    .report(event:
                        try event.normilize(configuration.events)
                    )
                )
            default:
                return context
            }
        }
        try next?.handle(normilizeFunction())
    }

}

private struct Constants {
    static let boolean = "Boolean"
}

extension OptimoveEvent {

    /// The normalization process contains next steps:
    /// - Replacing all spaces in a key with underscore character.
    /// - Handling Boolean type correctly.
    /// - Clean up an value of an non-normilized key.
    ///
    /// - Parameter event: The event for normilization.
    /// - Returns: Normilized event
    /// - Throws: Throw an error if an event configuration are missing.
    func normilize(_ events: [String: EventsConfig]) throws -> OptimoveEvent {
        guard let eventConfig = events[self.name] else {
            throw GuardError.custom("Configurations are missing for event \(self.name)")
        }
        let normalizedParameters = self.parameters.reduce(into: [String: Any]()) { (result, next) in
            // Replacing all spaces in a key with underscore character.
            let normalizedKey = next.key.replaceSpaces()

            // Handling Boolean type correctly.
            if let number = next.value as? NSNumber, eventConfig.parameters[normalizedKey]?.type == Constants.boolean {
                result[normalizedKey] = Bool(truncating: number)
            } else if let string = next.value as? String {
                result[normalizedKey] = string.trimmingCharacters(in: .whitespacesAndNewlines)
            } else {
                result[normalizedKey] = next.value
            }

            // Clean up an value of an non-normilized key.
            if normalizedKey != next.key {
                result[next.key] = nil
            }
        }
        return CommonOptimoveEvent(name: self.name, parameters: normalizedParameters)
    }

}

private extension String {

    private struct Constants {
        static let spaceCharacter = " "
        static let underscoreCharacter = "_"
    }

    func replaceSpaces(with replacement: String = Constants.underscoreCharacter) -> String {
        return self.lowercased()
            .trimmingCharacters(in: .whitespaces)
            .replacingOccurrences(of: Constants.spaceCharacter, with: replacement)
    }
}

final class ParametersDecorator: EventableHandler {

    private let configuration: Configuration

    init(configuration: Configuration) {
        self.configuration = configuration
    }

    override func handle(_ context: EventableOperationContext) throws {
        let decorationFunction = { [configuration] () -> EventableOperationContext in
            switch context.operation {
            case let .report(event: event):
                let pair = try event.matchConfiguration(with: configuration.events)
                return EventableOperationContext(
                    .report(event:
                        OptimoveEventDecorator(event: pair.event, config: pair.config)
                    )
                )
            default:
                return context
            }
        }
        try next?.handle(decorationFunction())
    }

}

extension OptimoveEvent {

    func matchConfiguration(with events: [String: EventsConfig]) throws -> (event: OptimoveEvent, config: EventsConfig) {
        guard let eventConfig = events[self.name] else {
            throw GuardError.custom("Configurations are missing for event \(self.name)")
        }
        return (self, eventConfig)
    }

}
