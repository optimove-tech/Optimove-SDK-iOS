//  Copyright © 2017 Optimove. All rights reserved.

import Foundation
import OptimoveCore

/// Describe operations that could be sent to MBaaS.
enum MbaasOperation: CustomStringConvertible {
    /// Add a new or update an existed user.
    case addOrUpdateUser
    /// Migrate a visitor to a customer user.
    case migrateUser

    var description: String {
        switch self {
        case .addOrUpdateUser:
            return "add_or_update_user"
        case .migrateUser:
            return "migrate_user"
        }
    }
}

protocol Registrable {
    func handle(_: MbaasOperation)
    func retryFailedOperationsIfExist() throws
}

final class Registrar {

    private var storage: OptimoveStorage
    private let networking: RegistrarNetworking
    private let handler: Handler

    init(storage: OptimoveStorage,
         networking: RegistrarNetworking) {
        self.storage = storage
        self.networking = networking
        self.handler = Handler(storage: storage)
    }

}

extension Registrar: Registrable {

    func handle(_ operation: MbaasOperation) {
        networking.sendToMbaas(operation: operation) { [handler] (result) in
            switch result {
            case .success:
                handler.handleSuccess(operation)
            case .failure:
                handler.handleFailed(operation)
            }
        }
    }

    func retryFailedOperationsIfExist() throws {
        if let isRegistrationSuccess = storage.isRegistrationSuccess, isRegistrationSuccess == false {
            handle(.addOrUpdateUser)
        }
        if let isUserMigrationSuccess = storage.isUserMigrationSuccess, isUserMigrationSuccess == false {
            handle(.migrateUser)
        }
    }

}

private extension Registrar {

    class Handler {

        private var storage: OptimoveStorage

        init(storage: OptimoveStorage) {
            self.storage = storage
        }

        func handleFailed(_ operation: MbaasOperation) {
           switch operation {
            case .addOrUpdateUser:
                storage.isRegistrationSuccess = false
            case .migrateUser:
                storage.isUserMigrationSuccess = false
            }
        }

        func handleSuccess(_ operation: MbaasOperation) {
            switch operation {
            case .addOrUpdateUser:
                storage.isRegistrationSuccess = true
            case .migrateUser:
                storage.isUserMigrationSuccess = true
            }
        }
    }

}
