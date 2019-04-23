import Foundation

class RealTimeConfigurator: OptimoveComponentConfigurator<RealTime> {
    override func setEnabled(from tenantConfig: TenantConfig) {
        component.isEnable = tenantConfig.enableRealtime
    }
    override func getRequirements() -> [OptimoveDeviceRequirement] {
        return [.internet]
    }
    override func executeInternalConfigurationLogic(from tenantConfig: TenantConfig,
                                                    didComplete: @escaping ResultBlockWithBool) {
        OptiLoggerMessages.logConfigrureRealtime()

        guard let realtimeMetadata = tenantConfig.realtimeMetaData else {
            OptiLoggerMessages.logRealtimeConfiguirationFailure()
            didComplete(false)
            return
        }
        setMetaData(realtimeMetadata)

        OptiLoggerMessages.logRealtimeCOnfigurationSuccess()
        didComplete(true)
    }

    private func setMetaData(_ realtimeMetaData: RealtimeMetaData) {
        component.metaData = realtimeMetaData
    }
}
