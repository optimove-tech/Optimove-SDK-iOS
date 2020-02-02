//  Copyright © 2019 Optimove. All rights reserved.

import Foundation
import UserNotifications
import OptimoveCore

final class OptiPush {

    private let registrar: Registrable
    private var storage: OptimoveStorage

    init(registrar: Registrable,
         storage: OptimoveStorage) {
        self.storage = storage
        self.registrar = registrar
        retryFailedMbaasOperations()
        Logger.debug("OptiPush initialized.")
    }

}

extension OptiPush: Component {

    func handle(_ context: OperationContext) throws {
        switch context.operation {
        case let .deviceToken(token: token):
            storage.apnsToken = token
            registrar.handle(.setUser)
            /// Alias`initialVisitorID` with `customerID` if the last one existed.
            /// Keep actual DB connections between the client aliases and the latest token.
            if (storage.customerID != nil) {
                registrar.handle(.addUserAlias)
            }
        case .migrateUser:
            guard storage.apnsToken != nil else { return }
            registrar.handle(.addUserAlias)
        case .optIn, .optOut:
            guard storage.apnsToken != nil else { return }
            registrar.handle(.setUser)
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
