import Foundation
import OptiTrackCore

class OptiTrackConfigurator: OptimoveComponentConfigurator<OptiTrack> {
    required init(component: OptiTrack) {
        super.init(component: component)
    }

    override func setEnabled(from tenantConfig: TenantConfig) {
       component.isEnable = tenantConfig.enableOptitrack
    }

    override func getRequirements() -> [OptimoveDeviceRequirement] {
        return[.advertisingId, .internet]
    }

    override func executeInternalConfigurationLogic(from tenantConfig: TenantConfig, didComplete:@escaping ResultBlockWithBool) {
        OptiLoggerMessages.logConfigureOptitrack()
        guard let optitrackMetadata = tenantConfig.optitrackMetaData else {
            OptiLoggerMessages.logOptitrackConfigurationInvalid()
            didComplete(false)
            return
        }
        setMetaData(optitrackMetadata)
        storeSiteIdInLocalStorage()
        setupTracker()
        OptiLoggerMessages.logOptitrackConfigurationSuccess()
        didComplete(true)
    }

    private func setMetaData(_ optitrackMetaData: OptitrackMetaData) {
        component.metaData = optitrackMetaData
    }

    private func storeSiteIdInLocalStorage() {
        OptimoveUserDefaults.shared.siteID = component.metaData.siteId
    }

    private func setupTracker() {
        if let url = URL.init(string: component.metaData.optitrackEndpoint) {
            component.tracker = MatomoTracker(siteId: String(component.metaData.siteId),
                                              baseURL: url,
                                              queue: component.queue,
                                              userAgent: nil)
        }
    }
}
