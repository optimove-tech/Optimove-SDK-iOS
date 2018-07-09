

import Foundation

class RealTimeConfigurator: OptimoveComponentConfigurator<RealTime>
{
    override func setEnabled(from tenantConfig:TenantConfig) {
        component.isEnable = tenantConfig.enableRealtime
    }
    override func getRequirements() -> [OptimoveDeviceRequirement] {
        return [.internet]
    }
    override func executeInternalConfigurationLogic(from tenantConfig:TenantConfig,
                                                    didComplete: @escaping ResultBlockWithBool)
    {
        OptiLogger.debug("Configure Realtime")
        
        guard let realtimeMetadata = tenantConfig.realtimeMetaData else {
            OptiLogger.error("👎🏻 real time configurations invalid")
            didComplete(false)
            return
        }
        setMetaData(realtimeMetadata)
        
        OptiLogger.debug("👍🏻 Realtime configuration succeed")
        didComplete(true)
    }
    
    private func setMetaData(_ realtimeMetaData: RealtimeMetaData)
    {
        component.metaData = realtimeMetaData
    }
}
