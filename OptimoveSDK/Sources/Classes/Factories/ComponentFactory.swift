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

    func createRealtimeComponent(configuration: Configuration) throws -> RealTime {
        let storage = serviceLocator.storage()
        return RealTime(
            configuration: configuration.realtime,
            storage: storage,
            networking: OptistreamNetworkingImpl(
                networkClient: serviceLocator.networkClient(),
                endpoint: configuration.realtime.realtimeGateway
            ),
            queue: try OptistreamQueueImpl(
                queueType: .realtime,
                container: PersistentContainer(modelName: PersistantModelNames.optistream),
                tenant: configuration.tenantID
            )
        )
    }

    func createOptipushComponent(configuration: Configuration) -> OptiPush {
        return OptiPush(
            registrar: serviceLocator.registrar(configuration: configuration),
            storage: serviceLocator.storage()
        )
    }

    func createOptitrackComponent(configuration: Configuration) throws -> OptiTrack {
        return OptiTrack(
            queue: try OptistreamQueueImpl(
                queueType: .track,
                container: PersistentContainer(modelName: PersistantModelNames.optistream),
                tenant: configuration.tenantID
            ),
            networking: OptistreamNetworkingImpl(
                networkClient: serviceLocator.networkClient(),
                endpoint: configuration.optitrack.optitrackEndpoint
            ),
            configuration: configuration.optitrack
        )
    }

    func createOptistreamEventBuilder(configuration: Configuration) -> OptistreamEventBuilder {
        return OptistreamEventBuilder(
            configuration: configuration.optitrack,
            storage: serviceLocator.storage(),
            airshipIntegration: OptimoveAirshipIntegration(
                storage: serviceLocator.storage(),
                configuration: configuration
            )
        )
    }

}
