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
        components.addComponent(componentFactory.createOptitrackComponent(configuration: configuration))
        components.addComponent(componentFactory.createRealtimeComponent(configuration: configuration))
        handlersPool.addNextEventableHandler(ComponentEventableHandler(component: components))
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
        MultiplexLoggerStream.mutateStreams { logger in
            logger.tenantId = config.tenantID
            logger.endpoint = config.logger.logServiceEndpoint
        }
    }
}
