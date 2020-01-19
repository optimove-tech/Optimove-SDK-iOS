//  Copyright © 2019 Optimove. All rights reserved.

import OptimoveCore

final class ComponentFactory {

    private let serviceLocator: ServiceLocator
    private let coreEventFactory: CoreEventFactory

    init(serviceLocator: ServiceLocator,
         coreEventFactory: CoreEventFactory) {
        self.serviceLocator = serviceLocator
        self.coreEventFactory = coreEventFactory
    }

    func createRealtimeComponent(configuration: Configuration) -> RealTime {
        let storage = serviceLocator.storage()
        return RealTime(
            configuration: configuration.realtime,
            storage: storage,
            networking: RealTimeNetworkingImpl(
                networkClient: serviceLocator.networking(),
                realTimeRequestBuildable: RealTimeRequestBuilder(),
                configuration: configuration.realtime
            ),
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

func createOptipushComponent(configuration: Configuration) -> OptiPush {
        let localServiceLocator = OptiPushServiceLocator(
            serviceLocator: serviceLocator,
            optipushConfig: configuration.optipush
        )
        return OptiPush(
            serviceProvider: localServiceLocator.serviceProvider(),
            registrar: localServiceLocator.registrar(),
            storage: serviceLocator.storage()
        )
    }

    func createOptitrackComponent(configuration: Configuration) -> OptiTrack {
        return OptiTrack(
            configuration: configuration.optitrack,
            storage: serviceLocator.storage(),
            coreEventFactory: coreEventFactory,
            tracker: MatomoTrackerAdapter(
                configuration: configuration.optitrack,
                storage: serviceLocator.storage()
            )
        )
    }

}
