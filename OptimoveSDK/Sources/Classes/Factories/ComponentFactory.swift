//  Copyright © 2019 Optimove. All rights reserved.

import OptimoveCore
import UIKit

final class ComponentFactory {
    private let serviceLocator: ServiceLocator
    private let coreEventFactory: CoreEventFactory
    private let persistentContainer: PersistentContainer

    init(serviceLocator: ServiceLocator,
         coreEventFactory: CoreEventFactory)
    {
        self.serviceLocator = serviceLocator
        self.coreEventFactory = coreEventFactory
        persistentContainer = PersistentContainer()
    }

    func createRealtimeComponent(configuration: Configuration) throws -> RealTime {
        let storage = serviceLocator.storage()
        return try RealTime(
            configuration: configuration.realtime,
            storage: storage,
            networking: OptistreamNetworkingImpl(
                networkClient: serviceLocator.networkClient(),
                endpoint: configuration.realtime.realtimeGateway
            ),
            queue: OptistreamQueueImpl(
                queueType: .realtime,
                container: persistentContainer,
                tenant: configuration.tenantID
            )
        )
    }

    func createOptitrackComponent(configuration: Configuration) throws -> OptiTrack {
        return try OptiTrack(
            queue: OptistreamQueueImpl(
                queueType: .track,
                container: persistentContainer,
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
            tenantID: configuration.optitrack.tenantID,
            storage: serviceLocator.storage()
        )
    }
}
