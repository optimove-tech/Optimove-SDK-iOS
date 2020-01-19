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
        let requestFactory = RegistrarNetworkingRequestFactory(
            storage: storage(),
            payloadBuilder: ApiPayloadBuilder(
                storage: storage(),
                appNamespace: try! Bundle.getApplicationNameSpace()
            ),
            requestBuilder: ClientAPIRequestBuilder(
                optipushConfig: optipushConfig
            )
        )
        let networking = RegistrarNetworkingImpl(
            networkClient: serviceLocator.networking(),
            requestFactory: requestFactory
        )
        return Registrar(
            storage: storage(),
            networking: networking
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
