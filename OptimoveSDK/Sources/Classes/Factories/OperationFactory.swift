//  Copyright © 2019 Optimove. All rights reserved.

import Foundation
import OptimoveCore

final class OperationFactory {
    private let configurationRepository: ConfigurationRepository
    private let networking: RemoteConfigurationNetworking

    init(configurationRepository: ConfigurationRepository,
         networking: RemoteConfigurationNetworking)
    {
        self.configurationRepository = configurationRepository
        self.networking = networking
    }

    func globalConfigurationDownloader() -> GlobalConfigurationDownloader {
        return GlobalConfigurationDownloader(
            networking: networking,
            repository: configurationRepository
        )
    }

    func tenantConfigurationDownloader() -> TenantConfigurationDownloader {
        return TenantConfigurationDownloader(
            networking: networking,
            repository: configurationRepository
        )
    }

    func mergeRemoteConfigurationOperation() -> MergeRemoteConfigurationOperation {
        return MergeRemoteConfigurationOperation(
            repository: configurationRepository
        )
    }
}
