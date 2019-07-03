import Foundation

class OptiPushConfigurator: OptimoveComponentConfigurator<OptiPush> {

    required init(component: OptiPush) {
        super.init(component: component)
    }

    override func setEnabled(from tenantConfig: TenantConfig) {
        component.isEnable = tenantConfig.enableOptipush
    }

    override func getRequirements() -> [OptimoveDeviceRequirement] {
        return [.userNotification, .internet]
    }

    override func executeInternalConfigurationLogic(
        from tenantConfig: TenantConfig,
        didComplete: @escaping ResultBlockWithBool
    ) {
        OptiLoggerMessages.logConfigureOptipush()
        guard let optipushMetadata = tenantConfig.optipushMetaData,
            let firebaseProjectKeys = tenantConfig.firebaseProjectKeys,
            let clientsServiceProjectKeys = tenantConfig.clientsServiceProjectKeys
        else {
            OptiLoggerMessages.logOptipushConfigurationFailure()
            didComplete(false)
            return
        }
        setMetaData(optipushMetadata)
        component.setup(
            firebaseMetaData: firebaseProjectKeys,
            clientFirebaseMetaData: clientsServiceProjectKeys,
            optipushMetaData: optipushMetadata
        )
        OptiLoggerMessages.logOptipushConfigurationSuccess()
        didComplete(true)
    }

    private func setMetaData(_ optipushMetadata: OptipushMetaData) {
        component.metaData = optipushMetadata
    }

}
