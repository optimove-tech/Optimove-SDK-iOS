//  Copyright © 2017 Optimove. All rights reserved.

import Foundation
import OptimoveCore

protocol Registrable {
    func register()
    func unregister(didComplete: @escaping ResultBlock)
    func optIn()
    func optOut()
    func retryFailedOperationsIfExist() throws
}

final class Registrar {

    private let modelFactory: MbaasModelFactory
    private var storage: OptimoveStorage
    private let networking: RegistrarNetworking
    private let backup: MbaasBackup

    init(storage: OptimoveStorage,
         modelFactory: MbaasModelFactory,
         networking: RegistrarNetworking,
         backup: MbaasBackup) {
        self.storage = storage
        self.modelFactory = modelFactory
        self.networking = networking
        self.backup = backup

        // WTF?
        OptiLoggerMessages.logRegistrarInitializtionStart()
        OptiLoggerMessages.logRegistrarInitializtionFinish()
    }

}

extension Registrar: Registrable {

    func register() {
        sendToMbaasModel(for: .registration)
    }

    func unregister(didComplete: @escaping ResultBlock) {
        sendToMbaasModel(for: .unregistration, completion: didComplete)
    }

    func optIn() {
        sendToMbaasModel(for: .optIn)
    }

    func optOut() {
        sendToMbaasModel(for: .optOut)
    }

    func retryFailedOperationsIfExist() throws {
        if !storage.isUnregistrationSuccess {
            let model = try backup.restoreLast(for: .unregistration) as MbaasModel
            retryFailedOperation(with: model)
        } else if !storage.isRegistrationSuccess {
            let model = try backup.restoreLast(for: .registration) as RegistartionMbaasModel
            retryFailedOperation(with: model)
        }
        if !storage.isOptRequestSuccess {
            let model = try backup.restoreLast(for: .optIn) as MbaasModel
            retryFailedOperation(with: model)
        }
    }

}

private extension Registrar {

    func sendToMbaasModel(for operation: MbaasOperation, completion: (() -> Void)? = nil) {
        do {
            let model = try modelFactory.createModel(for: operation)
            networking.sendToMbaas(model: model) { [weak self] (result) in
                switch result {
                case .success:
                    self?.handleSuccessMbaasModel(model)
                case .failure:
                    self?.handleFailedMbaasModel(model)
                }
                completion?()
            }
        } catch {
            OptiLoggerMessages.logJsonBuildFailure(mbaasRequestOperation: error.localizedDescription)
        }
    }

    func retryFailedOperation(with model: BaseMbaasModel) {
        networking.sendToMbaas(model: model) { [weak self] (result) in
            switch result {
            case .success:
                self?.handleSuccessMbaasModel(model)

                /// Helps prevent to keeping an old fcm token at server side, only for retry.
                if model.operation == .unregistration {
                    self?.register()
                }
            case .failure:
                OptiLoggerMessages.logRetryFailed()
            }
        }
    }

    func handleFailedMbaasModel(_ model: BaseMbaasModel) {
        do {
            try backup.backup(model)
            setSuccesFlag(succeed: false, for: model.operation)
        } catch {
            OptiLoggerMessages.logError(error: error)
        }
    }

    func handleSuccessMbaasModel(_ model: BaseMbaasModel) {
        do {
            try backup.clearLast(for: model.operation)
            setSuccesFlag(succeed: true, for: model.operation)
            if model.operation == .optIn {
                storage.isMbaasOptIn = true
            }
        } catch {
            OptiLoggerMessages.logError(error: error)
        }
    }

    func setSuccesFlag(succeed: Bool, for operation: MbaasOperation) {
        switch operation {
        case .optIn, .optOut:
            storage.isOptRequestSuccess = succeed
        case .registration:
            storage.isRegistrationSuccess = succeed
        case .unregistration:
            storage.isUnregistrationSuccess = succeed
        }
    }

}
