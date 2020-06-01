//  Copyright © 2019 Optimove. All rights reserved.

import OptimoveCore
import UIKit

final class ComponentFactory {

    private let serviceLocator: ServiceLocator
    private let coreEventFactory: CoreEventFactory
    private let persistentContainer: PersistentContainer

    init(serviceLocator: ServiceLocator,
         coreEventFactory: CoreEventFactory) {
        self.serviceLocator = serviceLocator
        self.coreEventFactory = coreEventFactory
        self.persistentContainer = PersistentContainer()
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
                container: self.persistentContainer,
                tenant: configuration.tenantID
            )
        )
    }

    func createOptipushComponent(configuration: Configuration) -> OptiPush {
        return OptiPush(
            registrar: serviceLocator.registrar(configuration: configuration),
            storage: serviceLocator.storage(),
            application: UIApplication.shared
        )
    }

    func createOptitrackComponent(configuration: Configuration) throws -> OptiTrack {
        return OptiTrack(
            queue: try OptistreamQueueImpl(
                queueType: .track,
                container: self.persistentContainer,
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
