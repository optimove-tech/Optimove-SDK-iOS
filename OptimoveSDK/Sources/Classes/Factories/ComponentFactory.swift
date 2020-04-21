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

    func createOptipushComponent(configuration: Configuration) -> OptiPush {
        return OptiPush(
            registrar: serviceLocator.registrar(configuration: configuration),
            storage: serviceLocator.storage()
        )
    }

    func createOptitrackComponent(configuration: Configuration) -> OptiTrack {
        return OptiTrack(
            tracker: OptistreamTracker(
                queue: OptistreamQueueImpl(
                    storage: serviceLocator.storage()
                ),
                optirstreamEventBuilder: OptistreamEventBuilder(
                    configuration: configuration.optitrack,
                    storage: serviceLocator.storage()
                )
            )
        )
    }

}
