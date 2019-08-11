import Foundation

final class RealTimeConfigurator: OptimoveComponentConfigurator<RealTime> {

    private let metaDataPriovider: MetaDataProvider<RealtimeMetaData>

    init(component: RealTime,
         metaDataPriovider: MetaDataProvider<RealtimeMetaData>) {
        self.metaDataPriovider = metaDataPriovider
        super.init(component: component)
    }

    @available(*, unavailable, renamed: "init(component:metaDataProvider:)")
    required init(component: T) {
        fatalError()
    }

    override func getRequirements() -> [OptimoveDeviceRequirement] {
        return [.internet]
    }

    override func executeInternalConfigurationLogic(
        from tenantConfig: TenantConfig,
        didComplete: @escaping ResultBlockWithBool
    ) {
        OptiLoggerMessages.logConfigrureRealtime()

        guard let realtimeMetaData = tenantConfig.realtimeMetaData else {
            OptiLoggerMessages.logRealtimeConfiguirationFailure()
            didComplete(false)
            return
        }

        metaDataPriovider.setMetaData(realtimeMetaData)

        OptiLoggerMessages.logRealtimeCOnfigurationSuccess()
        didComplete(true)
    }

}

