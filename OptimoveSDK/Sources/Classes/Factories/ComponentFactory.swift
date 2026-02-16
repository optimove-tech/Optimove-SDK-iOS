//  Copyright © 2019 Optimove. All rights reserved.

import OptimoveCore
import UIKit

final class ComponentFactory {
    private let serviceLocator: ServiceLocator
    private let coreEventFactory: CoreEventFactory
    private let persistentContainer: PersistentContainer
    private let authManager: AuthManager?

    init(serviceLocator: ServiceLocator,
         coreEventFactory: CoreEventFactory,
         authManager: AuthManager? = nil)
    {
        self.serviceLocator = serviceLocator
        self.coreEventFactory = coreEventFactory
        self.authManager = authManager
        persistentContainer = PersistentContainer()
    }

    func createRealtimeComponent(configuration: Configuration) throws -> RealTime {
        let storage = serviceLocator.storage()
        let networking = OptistreamNetworkingImpl(
            networkClient: serviceLocator.networkClient(),
            endpoint: configuration.realtime.realtimeGateway
        )
        let dispatcher = OptistreamDispatcherImpl(
            networking: networking,
            authManager: authManager
        )
        return try RealTime(
            configuration: configuration.realtime,
            storage: storage,
            dispatcher: dispatcher,
            queue: OptistreamQueueImpl(
                queueType: .realtime,
                container: persistentContainer,
                tenant: configuration.tenantID
            )
        )
    }

    func createOptitrackComponent(configuration: Configuration) throws -> OptiTrack {
        let networking = OptistreamNetworkingImpl(
            networkClient: serviceLocator.networkClient(),
            endpoint: configuration.optitrack.optitrackEndpoint
        )
        let dispatcher = OptistreamDispatcherImpl(
            networking: networking,
            authManager: authManager
        )
        return try OptiTrack(
            queue: OptistreamQueueImpl(
                queueType: .track,
                container: persistentContainer,
                tenant: configuration.tenantID
            ),
            dispatcher: dispatcher,
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
