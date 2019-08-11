// Copiright 2019 Optimove

import Foundation

final class ComponentConfiguratorFactory {

    private let serviceLocator: ServiceLocator
    private let optimoveInstance: Optimove

    init(serviceLocator: ServiceLocator,
         optimoveInstance: Optimove) {
        self.serviceLocator = serviceLocator
        self.optimoveInstance = optimoveInstance
    }

    func createOptiTrackConfigurator() -> OptiTrackConfigurator {
        return OptiTrackConfigurator(
            component: optimoveInstance.optiTrack,
            metaDataProvider: serviceLocator.optitrackMetaDataProvider(),
            storage: serviceLocator.storage()
        )
    }

    func createOptiPushConfigurator() -> OptiPushConfigurator {
        return OptiPushConfigurator(
            component: optimoveInstance.optiPush,
            metaDataProvider: serviceLocator.optipushMetaDataProvider()
        )
    }

    func createRealTimeConfigurator() -> RealTimeConfigurator {
        return RealTimeConfigurator(
            component: optimoveInstance.realTime,
            metaDataPriovider: serviceLocator.realtimeMetaDataProvider()
        )
    }
}
