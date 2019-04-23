import Foundation

struct OptimoveEventConfigsWarehouse {

    private let eventsConfigs: [String: OptimoveEventConfig]

    init(from tenantConfig: TenantConfig) {
        OptiLoggerMessages.logEventsWarehouseInitializtionStart()
        eventsConfigs = tenantConfig.events
        OptiLoggerMessages.logEventsWarehouseInitializtionFinish()
    }

    func getConfig(ofEvent event: OptimoveEvent) -> OptimoveEventConfig? {
        return eventsConfigs[event.name]
    }
}
