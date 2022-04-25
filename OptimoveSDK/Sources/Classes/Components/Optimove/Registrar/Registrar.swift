//  Copyright © 2017 Optimove. All rights reserved.

import Foundation
import OptimoveCore

protocol Registrable {
    func handle(_: ApiOperation)
    func retryFailedOperationsIfExist()
}

final class Registrar {

    private var storage: OptimoveStorage
    private let networking: ApiNetworking

    init(storage: OptimoveStorage,
         networking: ApiNetworking) {
        self.storage = storage
        self.networking = networking
    }

}

extension Registrar: Registrable {

    func handle(_ operation: ApiOperation) {
        networking.sendToMbaas(operation: operation) { (result) in
            switch result {
            case .success:
                self.handleSuccess(operation)
            case .failure(let error):
                self.handleFailed(operation, error)
            }
        }
    }

    func retryFailedOperationsIfExist() {
        if let isSettingUserSuccess = storage.isSettingUserSuccess, isSettingUserSuccess == false {
            handle(.setInstallation)
        }
    }

}

private extension Registrar {

    func handleFailed(_ operation: ApiOperation, _ error: Error) {
       switch operation {
        case .setInstallation:
            storage.isSettingUserSuccess = false
        }
    }

    func handleSuccess(_ operation: ApiOperation) {
        switch operation {
        case .setInstallation:
            storage.isSettingUserSuccess = true
        }
    }

}
