// Copiright 2019 Optimove

final class ComponentFactory {

    private let serviceLocator: ServiceLocator
    private let coreEventFactory: CoreEventFactory

    init(serviceLocator: ServiceLocator,
         coreEventFactory: CoreEventFactory) {
        self.serviceLocator = serviceLocator
        self.coreEventFactory = coreEventFactory
    }

    func createRealtimeComponent() -> RealTime {
        let metaDataProvider = serviceLocator.realtimeMetaDataProvider()
        let storage = serviceLocator.storage()
        return RealTime(
            storage: storage,
            networking: RealTimeNetworkingImpl(
                networkClient: serviceLocator.networking(),
                realTimeRequestBuildable: RealTimeRequestBuilder(),
                metaDataProvider: metaDataProvider
            ),
            warehouse: serviceLocator.warehouseProvider(),
            deviceStateMonitor: serviceLocator.deviceStateMonitor(),
            eventBuilder: RealTimeEventBuilder(
                metaDataProvider: metaDataProvider,
                storage: storage
            ),
            handler: RealTimeHanlderImpl(
                storage: storage
            ),
            coreEventFactory: CoreEventFactoryImpl(
                storage: storage,
                dateTimeProvider: serviceLocator.dateTimeProvider()
            )
        )
    }

    func createOptipushComponent() -> OptiPush {
        return OptiPush(
            deviceStateMonitor: serviceLocator.deviceStateMonitor(),
            infrastructure: FirebaseInteractor(
                storage: serviceLocator.storage(),
                networking: FirebaseInteractorNetworkingImpl(
                    networkClient: serviceLocator.networking(),
                    requestBuilder: FirebaseInteractorRequestBuilder(
                        storage: serviceLocator.storage(),
                        metaDataProvider: serviceLocator.optipushMetaDataProvider()
                    )
                )
            ),
            storage: serviceLocator.storage(),
            localServiceLocator: OptiPushServiceLocator(
                serviceLocator: serviceLocator
            )
        )
    }

    func createOptitrackComponent() -> OptiTrack {
        return OptiTrack(
            deviceStateMonitor: serviceLocator.deviceStateMonitor(),
            warehouseProvider: serviceLocator.warehouseProvider(),
            storage: serviceLocator.storage(),
            metaDataProvider: serviceLocator.optitrackMetaDataProvider(),
            coreEventFactory: coreEventFactory,
            dateTimeProvider: serviceLocator.dateTimeProvider(),
            statisticService: serviceLocator.statisticService()
        )
    }

}
