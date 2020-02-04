//  Copyright © 2017 Optimove. All rights reserved.

import Foundation
import OptimoveCore

protocol Registrable {
    func handle(_: ApiOperation)
    func retryFailedOperationsIfExist() throws
}

final class Registrar {

    private var storage: OptimoveStorage
    private let networking: ApiNetworking
    private let handler: Handler

    init(storage: OptimoveStorage,
         networking: ApiNetworking) {
        self.storage = storage
        self.networking = networking
        self.handler = Handler(storage: storage)
    }

}

extension Registrar: Registrable {

    func handle(_ operation: ApiOperation) {
        networking.sendToMbaas(operation: operation) { [handler] (result) in
            switch result {
            case .success:
                handler.handleSuccess(operation)
            case .failure(let error):
                handler.handleFailed(operation, error)
            }
        }
    }

    func retryFailedOperationsIfExist() throws {
        if let isSettingUserSuccess = storage.isSettingUserSuccess, isSettingUserSuccess == false {
            handle(.setUser)
        }
    }

}

private extension Registrar {

    class Handler {

        private var storage: OptimoveStorage

        init(storage: OptimoveStorage) {
            self.storage = storage
        }

        func handleFailed(_ operation: ApiOperation, _ error: Error) {
           switch operation {
            case .setUser:
                Logger.error("Set User operation was failed. \(error.localizedDescription)")
                storage.isSettingUserSuccess = false
            }
        }

        func handleSuccess(_ operation: ApiOperation) {
            switch operation {
            case .setUser:
                storage.isSettingUserSuccess = true
            }
        }
    }

}
