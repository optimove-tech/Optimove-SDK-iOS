//  Copyright © 2019 Optimove. All rights reserved.

import Foundation
import UserNotifications
import OptimoveCore

final class OptiPush {

    private let configuration: OptipushConfig
    private var serviceProvider: PushServiceProvider
    private let registrar: Registrable
    private var storage: OptimoveStorage

    init(configuration: OptipushConfig,
         serviceProvider: PushServiceProvider,
         registrar: Registrable,
         storage: OptimoveStorage) {
        self.configuration = configuration
        self.serviceProvider = serviceProvider
        self.storage = storage
        self.registrar = registrar

        self.serviceProvider.delegate = self
        performInitializationOperations()
        Logger.debug("OptiPush initialized.")
    }

    func performInitializationOperations() {
        retryFailedMbaasOperations()
    }

}

extension OptiPush: Component {

    func handle(_ context: OperationContext) throws {
        switch context.operation {
        case let .pushable(operation):
            switch operation {
            case let .deviceToken(token: data):
                serviceProvider.handleRegistration(apnsToken: data)
            case let  .subscribeToTopic(topic: topic):
                serviceProvider.subscribeToTopic(topic: topic)
            case let .unsubscribeFromTopic(topic: topic):
                serviceProvider.unsubscribeFromTopic(topic: topic)
            case .performRegistration:
                performRegistration()
            case .optIn:
                registrar.optIn()
            case .optOut:
                registrar.optOut()
            }
        default:
            break
        }
    }
}

extension OptiPush: PushServiceProviderDelegate {

    // MARK: - Protocol conformance

    func onRefreshToken() {
        let registerToken: () -> Void = {
            self.performRegistration()
            self.serviceProvider.subscribeToTopics()
        }
        if storage.isRegistrationSuccess {
            registrar.unregister {
                registerToken()
            }
        } else {
            registerToken()
        }
    }

}

private extension OptiPush {

    func performRegistration() {
        registrar.register()
    }

    func retryFailedMbaasOperations() {
        do {
            try registrar.retryFailedOperationsIfExist()
        } catch {
            Logger.error(error.localizedDescription)
        }
    }

}
