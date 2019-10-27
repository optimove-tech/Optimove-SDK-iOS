//  Copyright © 2019 Optimove. All rights reserved.

import Foundation
import UserNotifications
import OptimoveCore

final class OptiPush {

    private var serviceProvider: PushServiceProvider
    private let registrar: Registrable
    private var storage: OptimoveStorage

    init(serviceProvider: PushServiceProvider,
         registrar: Registrable,
         storage: OptimoveStorage) {
        self.serviceProvider = serviceProvider
        self.storage = storage
        self.registrar = registrar
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
                registrar.handle(.setUser)
                serviceProvider.handleRegistration(apnsToken: token)
            case let .subscribeToTopic(topic: topic):
                serviceProvider.subscribeToTopic(topic: topic)
            case let .unsubscribeFromTopic(topic: topic):
                serviceProvider.unsubscribeFromTopic(topic: topic)
            case .migrateUser:
                registrar.handle(.addUserAlias)
            case .optIn:
                registrar.handle(.setUser)
            case .optOut:
                registrar.handle(.setUser)
            }
        default:
            break
        }
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
