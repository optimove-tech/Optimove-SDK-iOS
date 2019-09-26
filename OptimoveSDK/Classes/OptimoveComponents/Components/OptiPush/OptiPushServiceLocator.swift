//  Copyright © 2019 Optimove. All rights reserved.

import Foundation
import OptimoveCore

final class OptiPushServiceLocator {

    private let serviceLocator: ServiceLocator
    private let optipushConfig: OptipushConfig

    init(serviceLocator: ServiceLocator,
         optipushConfig: OptipushConfig) {
        self.serviceLocator = serviceLocator
        self.optipushConfig = optipushConfig
    }

    func storage() -> OptimoveStorage {
        return serviceLocator.storage()
    }

    func registrar() -> Registrable {
        return Registrar(
            storage: storage(),
            networking: RegistrarNetworkingImpl(
                networkClient: serviceLocator.networking(),
                requestFactory: RegistrarNetworkingRequestFactory(
                    storage: storage(),
                    configuration: optipushConfig,
                    payloadBuilder: MbaasPayloadBuilder(
                        storage: storage(),
                        device: SDKDevice.self,
                        bundle: Bundle.self
                    )
                )
            )
        )
    }

    func serviceProvider() -> PushServiceProvider {
        let requestBuilder = FirebaseInteractorRequestBuilder(
            storage: serviceLocator.storage(),
            configuration: optipushConfig
        )
        let networking = FirebaseInteractorNetworkingImpl(
            networkClient: serviceLocator.networking(),
            requestBuilder: requestBuilder
        )
        return FirebaseInteractor(
            storage: storage(),
            networking: networking,
            optipush: optipushConfig
        )
    }

}
