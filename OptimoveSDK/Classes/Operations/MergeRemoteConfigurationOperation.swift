//  Copyright © 2019 Optimove. All rights reserved.

import Foundation

final class MergeRemoteConfigurationOperation: AsyncOperation {

    private let warehouseProvider: EventsConfigWarehouseProvider
    private let repository: ConfigurationRepository

    init(warehouseProvider: EventsConfigWarehouseProvider,
         repository: ConfigurationRepository) {
        self.warehouseProvider = warehouseProvider
        self.repository = repository
    }

    override func main() {
        state = .executing
        do {
            let globalConfig = try repository.getGlobal()
            let tenantConfig = try repository.getTenant()
            OptiLoggerMessages.logSetupComponentsFromRemote()

            // Set all events from Global and Tenant configs in one place.
            setEvents(globalConfig: globalConfig, tenantConfig: tenantConfig)

            let builder = ConfigurationBuilder(globalConfig: globalConfig, tenantConfig: tenantConfig)
            let configuration = builder.build()

            // Set the Configuration type for the runtime usage.
            try repository.setConfiguration(configuration)
        } catch {
            OptiLoggerMessages.logError(error: error)
        }
        self.state = .finished
    }

    private func setEvents(globalConfig: GlobalConfig, tenantConfig: TenantConfig) {
        let events = globalConfig.coreEvents.merging(tenantConfig.events,
                                                     uniquingKeysWith: { globalEvent, tenantEvent in globalEvent })
        warehouseProvider.setWarehouse(OptimoveEventConfigsWarehouseImpl(events: events))
    }
}
