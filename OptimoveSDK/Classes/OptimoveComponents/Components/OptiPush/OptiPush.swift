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
        retryFailedMbaasOperations()
        Logger.debug("OptiPush initialized.")
    }

}

extension OptiPush: Component {

    func handle(_ context: OperationContext) throws {
        switch context.operation {
        case let .pushable(operation):
            switch operation {
            case let .deviceToken(token: token):
                storage.apnsToken = token
                registrar.handle(.addOrUpdateUser)
                serviceProvider.handleRegistration(apnsToken: token)
            case let .subscribeToTopic(topic: topic):
                serviceProvider.subscribeToTopic(topic: topic)
            case let .unsubscribeFromTopic(topic: topic):
                serviceProvider.unsubscribeFromTopic(topic: topic)
            case .migrateUser:
                registrar.handle(.migrateUser)
            case .optIn:
                registrar.handle(.addOrUpdateUser)
            case .optOut:
                registrar.handle(.addOrUpdateUser)
            }
        default:
            break
        }
    }
}

extension OptiPush: PushServiceProviderDelegate {

    func onRefreshToken() {
        serviceProvider.subscribeToTopics()
    }

}
private extension OptiPush {

    func retryFailedMbaasOperations() {
        do {
            try registrar.retryFailedOperationsIfExist()
        } catch {
            Logger.error(error.localizedDescription)
        }
    }

}
