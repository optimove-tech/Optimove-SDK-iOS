import Foundation

protocol EventsConfigWarehouse {
    func getConfig(for event: OptimoveEvent) -> EventsConfig?
}

struct OptimoveEventConfigsWarehouseImpl: EventsConfigWarehouse {

    private let eventsConfigs: [String: EventsConfig]

    init(from tenantConfig: TenantConfig) {
        OptiLoggerMessages.logEventsWarehouseInitializtionStart()
        eventsConfigs = tenantConfig.events
        OptiLoggerMessages.logEventsWarehouseInitializtionFinish()
    }

    func getConfig(for event: OptimoveEvent) -> EventsConfig? {
        return eventsConfigs[event.name]
    }
}
