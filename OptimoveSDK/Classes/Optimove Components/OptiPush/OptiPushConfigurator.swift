import Foundation

final class OptiPushConfigurator: OptimoveComponentConfigurator<OptiPush> {

    private let metaDataProvider: MetaDataProvider<OptipushMetaData>

    required init(
        component: OptiPush,
        metaDataProvider: MetaDataProvider<OptipushMetaData>) {
        self.metaDataProvider = metaDataProvider
        super.init(component: component)
    }

    @available(*, unavailable, renamed: "init(component:metaDataProvider:)")
    required init(component: T) {
        fatalError("init(component:) has not been implemented. Use insted init(component:metaDataProvider:)")
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
        metaDataProvider.setMetaData(optipushMetadata)
        component.setup(
            firebaseMetaData: firebaseProjectKeys,
            clientFirebaseMetaData: clientsServiceProjectKeys,
            optipushMetaData: optipushMetadata
        )
        OptiLoggerMessages.logOptipushConfigurationSuccess()
        didComplete(true)
    }

}
