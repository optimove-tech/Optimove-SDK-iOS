import Foundation

final class OptiTrackConfigurator: OptimoveComponentConfigurator<OptiTrack> {

    private let metaDataProvider: MetaDataProvider<OptitrackMetaData>
    private let storage: OptimoveStorage

    required init(
        component: OptiTrack,
        metaDataProvider: MetaDataProvider<OptitrackMetaData>,
        storage: OptimoveStorage) {
        self.metaDataProvider = metaDataProvider
        self.storage = storage
        super.init(component: component)
    }

    @available(*, unavailable, renamed: "init(component:metaDataProvider:storage:)")
    required init(component: T) {
        fatalError()
    }

    override func getRequirements() -> [OptimoveDeviceRequirement] {
        return [.advertisingId, .internet]
    }

    override func executeInternalConfigurationLogic(
        from tenantConfig: TenantConfig,
        didComplete: @escaping ResultBlockWithBool
    ) {
        OptiLoggerMessages.logConfigureOptitrack()
        guard let optitrackMetadata = tenantConfig.optitrackMetaData else {
            OptiLoggerMessages.logOptitrackConfigurationInvalid()
            didComplete(false)
            return
        }
        do {
            updateMetaData(optitrackMetadata)
            try component.setupTracker()
            OptiLoggerMessages.logOptitrackConfigurationSuccess()
            didComplete(true)
        } catch {
            OptiLoggerMessages.logError(error: error)
            didComplete(false)
        }
    }

    private func updateMetaData(_ optitrackMetaData: OptitrackMetaData) {
        metaDataProvider.setMetaData(optitrackMetaData)
    }

}
