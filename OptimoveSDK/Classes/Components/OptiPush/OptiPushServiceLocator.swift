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
        let requestFactory = ApiRequestFactory(
            storage: storage(),
            payloadBuilder: ApiPayloadBuilder(
                storage: storage(),
                appNamespace: try! Bundle.getApplicationNameSpace()
            ),
            requestBuilder: ClientAPIRequestBuilder(
                optipushConfig: optipushConfig
            )
        )
        let networking = ApiNetworkingImpl(
            networkClient: serviceLocator.networking(),
            requestFactory: requestFactory
        )
        return Registrar(
            storage: storage(),
            networking: networking
        )
    }

    func serviceProvider() -> PushServiceProvider {
        return FirebaseInteractor(
            storage: storage(),
            optipush: optipushConfig
        )
    }

}
