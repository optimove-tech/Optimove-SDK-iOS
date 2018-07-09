
import Foundation

struct OptimoveEventConfigsWarehouse {
    
    private let eventsConfigs: [String:OptimoveEventConfig]
    
    init(from tenantConfig:TenantConfig)
    {
        OptiLogger.debug("Initialize events warehouse")
        eventsConfigs = tenantConfig.events
        OptiLogger.debug("Finished initialization of events warehouse")
    }
    
    func getConfig(ofEvent event: OptimoveEvent) -> OptimoveEventConfig? {
        return eventsConfigs[event.name]
    }
}
