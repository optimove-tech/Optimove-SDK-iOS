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
    func handleRegistration(token: Data)
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
    private let deviceStateMonitor: OptimoveDeviceStateMonitor

    init(configuration: OptipushConfig,
         deviceStateMonitor: OptimoveDeviceStateMonitor,
         infrastructure: OptipushServiceInfra,
         storage: OptimoveStorage,
         localServiceLocator: OptiPushServiceLocator) {
        self.configuration = configuration
        self.firebaseInteractor = infrastructure
        self.storage = storage
        self.serviceLocator = localServiceLocator
        self.deviceStateMonitor = deviceStateMonitor

        registrar = serviceLocator.registrar(configuration: configuration)
        firebaseInteractor.setupFirebase(
            from: configuration.firebaseProjectKeys,
            clientFirebaseMetaData: configuration.clientsServiceProjectKeys,
            delegate: self
        )

        performInitializationOperations()
    }

    func performInitializationOperations() {
        if RunningFlagsIndication.isComponentRunning(.optiPush) {
            self.retryFailedMbaasOperations()
            self.optInOutIfNeeded()
            firebaseInteractor.subscribeToTopics(didSucceed: nil)
            if let clientApnsToken = storage.apnsToken {
                application(didRegisterForRemoteNotificationsWithDeviceToken: clientApnsToken)
                storage.apnsToken = nil
            }
        }
    }

}

extension OptiPush: Pushable {

    func application(didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        firebaseInteractor.handleRegistration(token: deviceToken)
    }

    func subscribeToTopic(topic: String) {
        firebaseInteractor.subscribeToTopic(topic: topic, didSucceed: nil)
    }

    func unsubscribeFromTopic(topic: String) {
        firebaseInteractor.unsubscribeFromTopic(topic: topic, didSucceed: nil)
    }

    func performRegistration() {
        registrar.register()
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
            self.updateFcmTokenWith(token)
            self.performRegistration()
            self.firebaseInteractor.subscribeToTopics(didSucceed: nil)
        }
    }

}

private extension OptiPush {

    func handleFcmTokenReceivedForTheFirstTime(_ token: String) {
        OptiLoggerMessages.logClientreceiveFcmTOkenForTheFirstTime()
        storage.fcmToken = token
        performRegistration()
        firebaseInteractor.subscribeToTopics(didSucceed: nil)
    }

    func updateFcmTokenWith(_ fcmToken: String) {
        storage.fcmToken = fcmToken

    }

    func retryFailedMbaasOperations() {
        try? registrar.retryFailedOperationsIfExist()
    }

    func optInOutIfNeeded() {
        guard storage.isOptRequestSuccess else { return }
        deviceStateMonitor.getStatus(for: .userNotification) { (granted) in
            if granted {
                self.handleNotificationAuthorized()
            } else {
                self.handleNotificationRejection()
            }
        }
    }

    func handleNotificationAuthorizedAtFirstLaunch() {
        OptiLoggerMessages.logUserOptOPutFirstTime()
        storage.isMbaasOptIn = true
    }

    func handleNotificationAuthorized() {
        OptiLoggerMessages.logUserNotificationAuthorizedByUser()
        guard let isOptIn = storage.isMbaasOptIn else {  //Opt in on first launch
            handleNotificationAuthorizedAtFirstLaunch()
            return
        }
        if !isOptIn {
            OptiLoggerMessages.logOptinRequest()
            registrar.optIn()
        }
    }

    func handleNotificationRejection() {
        OptiLoggerMessages.logUserNotificationRejectedByUser()

        guard let isOptIn = storage.isMbaasOptIn else {
            //Opt out on first launch
            handleNotificationRejectionAtFirstLaunch()
            return
        }
        if isOptIn {
            OptiLoggerMessages.logOptoutRequest()
            registrar.optOut()
            storage.isMbaasOptIn = false
        }
    }

    func handleNotificationRejectionAtFirstLaunch() {
        OptiLoggerMessages.logOptOutFirstLaunch()
        guard storage.fcmToken != nil else {
            storage.isMbaasOptIn = false
            return
        }

        if storage.isRegistrationSuccess {
            storage.isMbaasOptIn = false
            registrar.optOut()
        }
    }
}
