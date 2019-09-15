//  Copyright © 2019 Optimove. All rights reserved.

import Foundation
import UserNotifications
import OptimoveCore

protocol OptipushServiceInfra {
    func subscribeToTopics(didSucceed: ((Bool) -> Void)?)
    func unsubscribeFromTopics()

    func setupFirebase(
        from: FirebaseProjectKeys,
        clientFirebaseMetaData: ClientsServiceProjectKeys,
        delegate: OptimoveMbaasRegistrationHandling
    )
    func handleRegistration(apnsToken: Data)
    func optimoveReceivedRegistrationToken(_ fcmToken: String)

    func subscribeToTopic(topic: String, didSucceed: ((Bool) -> Void)?)
    func unsubscribeFromTopic(topic: String, didSucceed: ((Bool) -> Void)?)
}

final class OptiPush {

    private let configuration: OptipushConfig
    private let firebaseInteractor: OptipushServiceInfra
    private let registrar: Registrable
    private var storage: OptimoveStorage
    private let serviceLocator: OptiPushServiceLocator

    init(configuration: OptipushConfig,
         infrastructure: OptipushServiceInfra,
         storage: OptimoveStorage,
         localServiceLocator: OptiPushServiceLocator) {
        self.configuration = configuration
        self.firebaseInteractor = infrastructure
        self.storage = storage
        self.serviceLocator = localServiceLocator

        registrar = serviceLocator.registrar(configuration: configuration)
        firebaseInteractor.setupFirebase(
            from: configuration.firebaseProjectKeys,
            clientFirebaseMetaData: configuration.clientsServiceProjectKeys,
            delegate: self
        )

        performInitializationOperations()
        Logger.debug("OptiPush initialized.")
    }

    func performInitializationOperations() {
        retryFailedMbaasOperations()
    }

}

extension OptiPush: PushableComponent {

    func handlePushable(_ context: PushableOperationContext) throws {
        switch context.operation {
        case let .deviceToken(token: data):
            firebaseInteractor.handleRegistration(apnsToken: data)
        case let  .subscribeToTopic(topic: topic):
            firebaseInteractor.subscribeToTopic(topic: topic, didSucceed: nil)
        case let .unsubscribeFromTopic(topic: topic):
            firebaseInteractor.unsubscribeFromTopic(topic: topic, didSucceed: nil)
        case .performRegistration:
            performRegistration()
        case .optIn:
            registrar.optIn()
        case .optOut:
            registrar.optOut()
        }
    }
}

extension OptiPush: OptimoveMbaasRegistrationHandling {

    // MARK: - Protocol conformance

    func handleRegistrationTokenRefresh(token: String) {
        guard let _ = storage.fcmToken else {
            handleFcmTokenReceivedForTheFirstTime(token)
            return
        }

        registrar.unregister {
            //The order of the following operations matter
            self.storage.fcmToken = token
            self.performRegistration()
            self.firebaseInteractor.subscribeToTopics(didSucceed: nil)
        }
    }

}

private extension OptiPush {

    func performRegistration() {
        registrar.register()
    }

    func handleFcmTokenReceivedForTheFirstTime(_ token: String) {
        Logger.debug("OptiPush: Client receive a token for the first time.")
        storage.fcmToken = token
        performRegistration()
        firebaseInteractor.subscribeToTopics(didSucceed: nil)
    }


    func retryFailedMbaasOperations() {
        do {
            try registrar.retryFailedOperationsIfExist()
        } catch {
            Logger.error(error.localizedDescription)
        }
    }

}
