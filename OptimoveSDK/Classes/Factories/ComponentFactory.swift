// Copiright 2019 Optimove

final class ComponentFactory {

    private let serviceLocator: ServiceLocator
    private let coreEventFactory: CoreEventFactory

    init(serviceLocator: ServiceLocator,
         coreEventFactory: CoreEventFactory) {
        self.serviceLocator = serviceLocator
        self.coreEventFactory = coreEventFactory
    }

    func createRealtimeComponent() throws -> RealTime {
        let configuration = try serviceLocator.configurationRepository().getConfiguration()
        let storage = serviceLocator.storage()
        return RealTime(
            configuration: configuration.realtime,
            storage: storage,
            networking: RealTimeNetworkingImpl(
                networkClient: serviceLocator.networking(),
                realTimeRequestBuildable: RealTimeRequestBuilder(),
                configuration: configuration.realtime
            ),
            warehouse: serviceLocator.warehouseProvider(),
            deviceStateMonitor: serviceLocator.deviceStateMonitor(),
            eventBuilder: RealTimeEventBuilder(
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

    func createOptipushComponent() throws -> OptiPush {
        let configuration = try serviceLocator.configurationRepository().getConfiguration()
        return OptiPush(
            configuration: configuration.optipush,
            deviceStateMonitor: serviceLocator.deviceStateMonitor(),
            infrastructure: FirebaseInteractor(
                storage: serviceLocator.storage(),
                networking: FirebaseInteractorNetworkingImpl(
                    networkClient: serviceLocator.networking(),
                    requestBuilder: FirebaseInteractorRequestBuilder(
                        storage: serviceLocator.storage(),
                        configuration: configuration.optipush
                    )
                )
            ),
            storage: serviceLocator.storage(),
            localServiceLocator: OptiPushServiceLocator(
                serviceLocator: serviceLocator
            )
        )
    }

    func createOptitrackComponent() throws -> OptiTrack {
        let configuration = try serviceLocator.configurationRepository().getConfiguration()
        return OptiTrack(
            configuration: configuration.optitrack,
            deviceStateMonitor: serviceLocator.deviceStateMonitor(),
            warehouseProvider: serviceLocator.warehouseProvider(),
            storage: serviceLocator.storage(),
            coreEventFactory: coreEventFactory,
            dateTimeProvider: serviceLocator.dateTimeProvider(),
            statisticService: serviceLocator.statisticService(),
            tracker: MatomoTrackerAdapter(
                configuration: configuration.optitrack,
                storage: serviceLocator.storage()
            )
        )
    }

}
