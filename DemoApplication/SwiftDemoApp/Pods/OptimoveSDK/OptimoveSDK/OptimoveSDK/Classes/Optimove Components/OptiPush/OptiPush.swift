//  Optipush.swift
//  iOS-SDK

import Foundation
import UserNotifications

protocol OptipushServiceInfra {
    func subscribeToTopics(didSucceed: ((Bool)->Void)?)
    func unsubscribeFromTopics()
    func setupFirebase(from firebaseMetaData: FirebaseProjectKeys,
                       clientFirebaseMetaData: ClientsServiceProjectKeys,
                       delegate: OptimoveMbaasRegistrationHandling,
                       pushTopicsRegistrationEndpoint: String)
    func handleRegistration(token: Data)
    func optimoveReceivedRegistrationToken(_ fcmToken: String)

    func subscribeToTopic(topic: String, didSucceed: ((Bool)->Void)?)
    func unsubscribeFromTopic(topic: String, didSucceed: ((Bool)->Void)?)
}

final class OptiPush: OptimoveComponent {
    // MARK: - Variables
    var metaData: OptipushMetaData!
    private var firebaseInteractor: OptipushServiceInfra
    private var registrar: RegistrationProtocol?

    init(deviceStateMonitor: OptimoveDeviceStateMonitor, infrastructure: OptipushServiceInfra = FirebaseInteractor()) {
        self.firebaseInteractor = infrastructure
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
    func setup(firebaseMetaData: FirebaseProjectKeys,
               clientFirebaseMetaData: ClientsServiceProjectKeys,
               optipushMetaData: OptipushMetaData) {
        registrar = Registrar(optipushMetaData: optipushMetaData)
        firebaseInteractor.setupFirebase(from: firebaseMetaData,
                                         clientFirebaseMetaData: clientFirebaseMetaData,
                                         delegate: self,
                                         pushTopicsRegistrationEndpoint: optipushMetaData.pushTopicsRegistrationEndpoint)
    }

    func application(didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        firebaseInteractor.handleRegistration(token: deviceToken)
    }

    func subscribeToTopic(topic: String, didSucceed: ((Bool)->Void)?  = nil) {
        if isEnable {
            firebaseInteractor.subscribeToTopic(topic: topic, didSucceed: didSucceed)
        } else {
            didSucceed?(false)
        }
    }
    func unsubscribeFromTopic(topic: String, didSucceed: ((Bool)->Void)? = nil) {
        if isEnable {
            firebaseInteractor.unsubscribeFromTopic(topic: topic, didSucceed: didSucceed)
        } else {
            didSucceed?(false)
        }
    }

    func performRegistration() {
        registrar?.register()
    }
}

extension OptiPush: OptimoveMbaasRegistrationHandling {
    // MARK: - Protocol conformance
    func handleRegistrationTokenRefresh(token: String) {
        guard let _ = OptimoveUserDefaults.shared.fcmToken else {
            handleFcmTokenReceivedForTheFirstTime(token)
            return
        }

        registrar?.unregister { (_) in

            //The order of the following operations matter
            self.updateFcmTokenWith(token)
            self.performRegistration()
            self.firebaseInteractor.subscribeToTopics(didSucceed: nil)
        }
    }

    private func handleFcmTokenReceivedForTheFirstTime(_ token: String) {
        OptiLoggerMessages.logClientreceiveFcmTOkenForTheFirstTime()
        OptimoveUserDefaults.shared.fcmToken = token
        performRegistration()
        firebaseInteractor.subscribeToTopics(didSucceed: nil)
    }

    private func updateFcmTokenWith(_ fcmToken: String) {
        OptimoveUserDefaults.shared.fcmToken = fcmToken
    }

    private func retryFailedMbaasOperations() {
        registrar?.retryFailedOperationsIfExist()
    }
}

extension OptiPush {
    private func optInOutIfNeeded() {
        guard OptimoveUserDefaults.shared.isOptRequestSuccess else {return}
        deviceStateMonitor.getStatus(of: .userNotification) { (granted) in
            if granted {
                self.handleNotificationAuthorized()
            } else {
                self.handleNotificationRejection()
            }
        }
    }
    private func handleNotificationAuthorizedAtFirstLaunch() {
        OptiLoggerMessages.logUserOptOPutFirstTime()
        OptimoveUserDefaults.shared.isMbaasOptIn = true
    }
    private func handleNotificationAuthorized() {
        OptiLoggerMessages.logUserNotificationAuthorizedByUser()
        guard let isOptIn = OptimoveUserDefaults.shared.isMbaasOptIn else { //Opt in on first launch
            handleNotificationAuthorizedAtFirstLaunch()
            return
        }
        if !isOptIn {
            OptiLoggerMessages.logOptinRequest()
            self.registrar?.optIn()

        }
    }
    private func handleNotificationRejection() {
        OptiLoggerMessages.logUserNotificationRejectedByUser()

        guard let isOptIn = OptimoveUserDefaults.shared.isMbaasOptIn else {
            //Opt out on first launch
            handleNotificationRejectionAtFirstLaunch()
            return
        }
        if isOptIn {
            OptiLoggerMessages.logOptoutRequest()
            registrar?.optOut()
            OptimoveUserDefaults.shared.isMbaasOptIn = false
        }
    }
    private func handleNotificationRejectionAtFirstLaunch() {
        OptiLoggerMessages.logOptOutFirstLaunch()
        guard OptimoveUserDefaults.shared.fcmToken != nil else {
            OptimoveUserDefaults.shared.isMbaasOptIn = false
            return
        }

        if OptimoveUserDefaults.shared.isRegistrationSuccess {
            OptimoveUserDefaults.shared.isMbaasOptIn = false
            self.registrar?.optOut()
        }
    }
}
