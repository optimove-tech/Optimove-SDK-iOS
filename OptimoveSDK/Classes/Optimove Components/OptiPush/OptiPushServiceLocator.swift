// Copiright 2019 Optimove

import Foundation

final class OptiPushServiceLocator {

    private let serviceLocator: ServiceLocator

    init(serviceLocator: ServiceLocator) {
        self.serviceLocator = serviceLocator
    }

    func storage() -> OptimoveStorage {
        return serviceLocator.storage()
    }

    func registrar(configuration: OptipushConfig) -> Registrable {
        return Registrar(
            storage: storage(),
            modelFactory: MbaasModelFactory(
                storage: storage(),
                processInfo: ProcessInfo(),
                device: Device.self,
                bundle: Bundle.self
            ),
            networking: RegistrarNetworkingImpl(
                networkClient: serviceLocator.networking(),
                requestBuilder: RegistrarNetworkingRequestBuilder(
                    storage: storage(),
                    configuration: configuration
                )
            ),
            backup: MbaasBackupImpl(
                storage: storage(),
                encoder: JSONEncoder(),
                decoder: JSONDecoder()
            )
        )
    }

}
