//  Copyright © 2017 Optimove. All rights reserved.

import Foundation
import OptimoveCore

/// Describe operations that could be sent to MBaaS.
enum MbaasOperation: CustomStringConvertible {
    /// Set a new or update an existed user.
    case setUser
    /// Add ut a user additional alias, as a visitior or a customer ID.
    case addUserAlias

    var description: String {
        switch self {
        case .setUser:
            return "set_user"
        case .addUserAlias:
            return "add_user_alias"
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
        if let isSettingUserSuccess = storage.isSettingUserSuccess, isSettingUserSuccess == false {
            handle(.setUser)
        }
        if let isAddingUserAliasSuccess = storage.isAddingUserAliasSuccess, isAddingUserAliasSuccess == false {
            handle(.addUserAlias)
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
            case .setUser:
                storage.isSettingUserSuccess = false
            case .addUserAlias:
                storage.isAddingUserAliasSuccess = false
                if let customerID = storage.customerID {
                    var failedCustomerIDs: Set<String> = storage.failedCustomerIDs
                    failedCustomerIDs.insert(customerID)
                    storage.failedCustomerIDs = failedCustomerIDs
                }
            }
        }

        func handleSuccess(_ operation: MbaasOperation) {
            switch operation {
            case .setUser:
                storage.isSettingUserSuccess = true
            case .addUserAlias:
                storage.isAddingUserAliasSuccess = true
                storage.failedCustomerIDs = []
            }
        }
    }

}
