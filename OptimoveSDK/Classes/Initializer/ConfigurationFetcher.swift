//  Copyright © 2019 Optimove. All rights reserved.

import Foundation
import OptimoveCore

final class ConfigurationFetcher {

    private let operationQueue: OperationQueue
    private let operationFactory: OperationFactory
    private let configurationRepository: ConfigurationRepository

    init(operationFactory: OperationFactory,
         configurationRepository: ConfigurationRepository) {
        self.operationFactory = operationFactory
        self.configurationRepository = configurationRepository
        self.operationQueue = OperationQueue()
        self.operationQueue.qualityOfService = .utility
    }

    func fetch(completion: @escaping (Result<Configuration, Error>) -> Void) {
        // Operations that execute asynchronously to fetch remote configs.
        let downloadOperations: [Operation] = [
            operationFactory.globalConfigurationDownloader(),
            operationFactory.tenantConfigurationDownloader()
        ]

        // Operation merge all remote configs to a invariant.
        let mergeOperation = operationFactory.mergeRemoteConfigurationOperation()

        // Set the merge operation as dependent on the download operations.
        downloadOperations.forEach {
            mergeOperation.addDependency($0)
        }

        // Set the completion operation for aline two asynchronous operations together.
        let completionOperation = BlockOperation {
            // If there no configuration file either downloaded or stored, the SDK cannot be initialized.
            completion(
                Result(catching: {
                    return try self.configurationRepository.getConfiguration()
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

}
