//  Optipush.swift
//  iOS-SDK

import Foundation
import UserNotifications

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

final class OptiPush: OptimoveComponent {

    private var firebaseInteractor: OptipushServiceInfra
    private var registrar: Registrable?
    private var storage: OptimoveStorage
    private let serviceLocator: OptiPushServiceLocator

    init(deviceStateMonitor: OptimoveDeviceStateMonitor,
         infrastructure: OptipushServiceInfra,
         storage: OptimoveStorage,
         localServiceLocator: OptiPushServiceLocator) {
        self.firebaseInteractor = infrastructure
        self.storage = storage
        self.serviceLocator = localServiceLocator
        super.init(deviceStateMonitor: deviceStateMonitor)
    }

    override func performInitializationOperations() {
        if RunningFlagsIndication.isComponentRunning(.optiPush) {
            self.retryFailedMbaasOperations()
            self.optInOutIfNeeded()
            firebaseInteractor.subscribeToTopics(didSucceed: nil)
        }
    }

    // MARK: - Internal methods
    func setup(
        firebaseMetaData: FirebaseProjectKeys,
        clientFirebaseMetaData: ClientsServiceProjectKeys,
        optipushMetaData: OptipushMetaData
    ) {
        registrar = serviceLocator.registrar(metaData: optipushMetaData)
        firebaseInteractor.setupFirebase(
            from: firebaseMetaData,
            clientFirebaseMetaData: clientFirebaseMetaData,
            delegate: self
        )
    }

    func application(didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        firebaseInteractor.handleRegistration(token: deviceToken)
    }

    func subscribeToTopic(topic: String, didSucceed: ((Bool) -> Void)? = nil) {
        firebaseInteractor.subscribeToTopic(topic: topic, didSucceed: didSucceed)
    }

    func unsubscribeFromTopic(topic: String, didSucceed: ((Bool) -> Void)? = nil) {
        firebaseInteractor.unsubscribeFromTopic(topic: topic, didSucceed: didSucceed)
    }

    func performRegistration() {
        registrar?.register()
    }
}

extension OptiPush: OptimoveMbaasRegistrationHandling {
    // MARK: - Protocol conformance
    func handleRegistrationTokenRefresh(token: String) {
        guard let _ = storage.fcmToken else {
            handleFcmTokenReceivedForTheFirstTime(token)
            return
        }

        registrar?.unregister {
            //The order of the following operations matter
            self.updateFcmTokenWith(token)
            self.performRegistration()
            self.firebaseInteractor.subscribeToTopics(didSucceed: nil)
        }
    }

    private func handleFcmTokenReceivedForTheFirstTime(_ token: String) {
        OptiLoggerMessages.logClientreceiveFcmTOkenForTheFirstTime()
        storage.fcmToken = token
        performRegistration()
        firebaseInteractor.subscribeToTopics(didSucceed: nil)
    }

    private func updateFcmTokenWith(_ fcmToken: String) {
        storage.fcmToken = fcmToken

    }

    private func retryFailedMbaasOperations() {
        try? registrar?.retryFailedOperationsIfExist()
    }
}

extension OptiPush {
    private func optInOutIfNeeded() {
        guard storage.isOptRequestSuccess else { return }
        deviceStateMonitor.getStatus(for: .userNotification) { (granted) in
            if granted {
                self.handleNotificationAuthorized()
            } else {
                self.handleNotificationRejection()
            }
        }
    }

    private func handleNotificationAuthorizedAtFirstLaunch() {
        OptiLoggerMessages.logUserOptOPutFirstTime()
        storage.isMbaasOptIn = true
    }

    private func handleNotificationAuthorized() {
        OptiLoggerMessages.logUserNotificationAuthorizedByUser()
        guard let isOptIn = storage.isMbaasOptIn else {  //Opt in on first launch
            handleNotificationAuthorizedAtFirstLaunch()
            return
        }
        if !isOptIn {
            OptiLoggerMessages.logOptinRequest()
            registrar?.optIn()

        }
    }

    private func handleNotificationRejection() {
        OptiLoggerMessages.logUserNotificationRejectedByUser()

        guard let isOptIn = storage.isMbaasOptIn else {
            //Opt out on first launch
            handleNotificationRejectionAtFirstLaunch()
            return
        }
        if isOptIn {
            OptiLoggerMessages.logOptoutRequest()
            registrar?.optOut()
            storage.isMbaasOptIn = false
        }
    }

    private func handleNotificationRejectionAtFirstLaunch() {
        OptiLoggerMessages.logOptOutFirstLaunch()
        guard storage.fcmToken != nil else {
            storage.isMbaasOptIn = false
            return
        }

        if storage.isRegistrationSuccess {
            storage.isMbaasOptIn = false
            self.registrar?.optOut()
        }
    }
}
