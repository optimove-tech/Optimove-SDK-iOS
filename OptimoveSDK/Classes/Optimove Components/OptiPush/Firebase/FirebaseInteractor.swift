//
//  FirebaseInteractor.swift
//  OptimoveSDK
//
//  Created by Mobile Developer Optimove on 26/09/2017.
//  Copyright © 2017 Optimove. All rights reserved.
//

import FirebaseCore
import FirebaseMessaging
import Foundation
import os.log

protocol OptimoveMbaasRegistrationHandling: class {
    func handleRegistrationTokenRefresh(token: String)
}

final class FirebaseInteractor: NSObject {

    weak var delegate: OptimoveMbaasRegistrationHandling?
    var appController: FirebaseOptions?
    var clientServiceOptions: FirebaseOptions?

    private var storage: OptimoveStorage
    private let networking: FirebaseInteractorNetworking

    init(storage: OptimoveStorage,
         networking: FirebaseInteractorNetworking) {
        self.storage = storage
        self.networking = networking
    }

}

extension FirebaseInteractor: OptipushServiceInfra {

    func subscribeToTopics(didSucceed: ((Bool) -> Void)? = nil) {
        let dict = OptimoveTopicsUserDefaults.topics?.dictionaryRepresentation()
        dict?.forEach { (key, _) in
            if key.hasPrefix("optimove_") {
                subscribeToTopic(topic: key.deletingPrefix("optimove_"))
            }
        }
        subscribeToTopic(topic: "optipush_general")
        subscribeToTopic(topic: "ios")
        subscribeToTopic(topic: getMongoTypeBundleId())
    }

    func unsubscribeFromTopics() {
        let dict = OptimoveTopicsUserDefaults.topics?.dictionaryRepresentation()
        dict?.forEach { (key, _) in
            if key.hasPrefix("optimove_") {
                unsubscribeFromTopic(topic: key.deletingPrefix("optimove_"))
            }
        }
    }

    func setupFirebase(
        from firebaseMetaData: FirebaseProjectKeys,
        clientFirebaseMetaData: ClientsServiceProjectKeys,
        delegate: OptimoveMbaasRegistrationHandling
    ) {
        OptiLoggerMessages.logSetupFirebase()

        self.delegate = delegate
        let appController = FirebaseOptionsBuilder(
            provider: firebaseMetaData,
            bundleID: try! Bundle.getApplicationNameSpace()
        ).build()
        self.appController = appController

        let clientServiceOptions = FirebaseOptionsBuilder(
            provider: clientFirebaseMetaData,
            bundleID: try! Bundle.getApplicationNameSpace()
            ).build()
        self.clientServiceOptions = clientServiceOptions

        setupAppController(appController)
        setupSdkController(clientServiceOptions)

        if let token = Messaging.messaging().fcmToken {
            registerIfTokenChanged(updatedFcmToken: token)
        } else {
            NotificationCenter.default.addObserver(
                forName: NSNotification.Name.MessagingRegistrationTokenRefreshed,
                object: nil,
                queue: .main
            ) { (_) in
                self.registerIfTokenChanged(updatedFcmToken: Messaging.messaging().fcmToken)
            }
        }
        OptiLoggerMessages.logFirebaseStupFinished()
    }

    func handleRegistration(token: Data) {
        Messaging.messaging().apnsToken = token
    }

    func optimoveReceivedRegistrationToken(_ fcmToken: String) {
        if storage.isClientHasFirebase {
            guard storage.defaultFcmToken != fcmToken else {
                OptiLoggerMessages.logFcmTokenNotNew()
                OptiLoggerMessages.logFcmTokenForAppController(fcmToken: fcmToken)
                return
            }
            guard let optimoveAppSenderId = self.appController?.gcmSenderID else {
                OptiLoggerMessages.logAppControllerNotConfigure()
                return
            }
            OptiLoggerMessages.logOldFcmToken(token: String(describing: storage.fcmToken ?? ""))
            retreiveFcmToken(for: optimoveAppSenderId) { [weak self] (token) in
                OptiLoggerMessages.logNewFcmToken(token: token)
                self?.delegate?.handleRegistrationTokenRefresh(token: token)
                self?.storage.defaultFcmToken = fcmToken
            }
        } else {
            OptiLoggerMessages.logFcmTokenForAppController(fcmToken: fcmToken)
            self.delegate?.handleRegistrationTokenRefresh(token: fcmToken)
        }
    }

    func subscribeToTopic(topic: String, didSucceed: ((Bool) -> Void)? = nil) {
        if !storage.isClientHasFirebase {
            Messaging.messaging().subscribe(toTopic: topic) { (error) in
                if error != nil {
                    didSucceed?(false)
                } else {
                    didSucceed?(true)
                }
            }
        } else {
            networking.subscribe(topic: topic) { (result) in
                switch result {
                case .success(_):
                    os_log(
                        "Subscribed topic '%{private}@' successful.",
                        log: OSLog.firebaseInteractor,
                        type: .info,
                        topic
                    )
                    OptimoveTopicsUserDefaults.topics?.set(true, forKey: "optimove_\(topic)")
                    didSucceed?(true)
                case let .failure(error):
                    OptiLoggerMessages.logError(error: error)
                    OptimoveTopicsUserDefaults.topics?.set(false, forKey: "optimove_\(topic)")
                    didSucceed?(false)
                }
            }
        }
    }

    func unsubscribeFromTopic(topic: String, didSucceed: ((Bool) -> Void)? = nil) {
        if !storage.isClientHasFirebase {
            Messaging.messaging().unsubscribe(fromTopic: topic) { (error) in
                if error != nil {
                    didSucceed?(false)
                } else {
                    didSucceed?(true)
                }
            }
        } else {
            networking.unsubscribe(topic: topic) { (result) in
                switch result {
                case .success(_):
                    os_log(
                        "Unsubscribed topic '%{private}@' successful.",
                        log: OSLog.firebaseInteractor,
                        type: .info,
                        topic
                    )
                    OptimoveTopicsUserDefaults.topics?.removeObject(forKey: "optimove_\(topic)")
                    didSucceed?(true)
                case let .failure(error):
                    OptiLoggerMessages.logError(error: error)
                    didSucceed?(false)
                }
            }
        }
    }

}

extension FirebaseInteractor: MessagingDelegate {

//    func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String) {
//
//    }
//
//    func messaging(_ messaging: Messaging, didReceive remoteMessage: MessagingRemoteMessage) {
//
//    }

}

private extension FirebaseInteractor {

    func setupAppController(_ appController: FirebaseOptions) {
        if FirebaseApp.app() != nil {
            OptiLoggerMessages.logUserUseAutonomousFirebase(logModule: "OptiPush")
            FirebaseApp.configure(
                name: "appController",
                options: appController
            )
            storage.isClientHasFirebase = true
        } else {
            OptiLoggerMessages.logUserNotUseOwnFirebase()
            storage.isClientHasFirebase = false
            FirebaseApp.configure(options: appController)
        }
    }

    func setupSdkController(_ clientServiceOptions: FirebaseOptions) {
        FirebaseApp.configure(name: "sdkController", options: clientServiceOptions)
    }

    func registerIfTokenChanged(updatedFcmToken: String?) {
        let isTokenNew = updatedFcmToken != nil && storage.fcmToken != updatedFcmToken
        if isTokenNew {
            optimoveReceivedRegistrationToken(updatedFcmToken!)
        }
    }

    func isNewFcmToken(receivedToken received: String) -> Bool {
        if let oldFCM = storage.fcmToken {
            return received != oldFCM
        }
        return true
    }

    func retreiveFcmToken(for senderId: String, completion: @escaping (String) -> Void) {
        Messaging.messaging().retrieveFCMToken(forSenderID: senderId) { (token, error) in
            guard error == nil else {
                OptiLoggerMessages.logFcmTOkenRetreiveError(errorDescription: error.debugDescription)
                return
            }
            if let token = token {
                completion(token)
            }
        }
    }

    func getMongoTypeBundleId() -> String {
        return Bundle.main.bundleIdentifier?.setAsMongoKey() ?? ""
    }
}

extension OSLog {
    static let firebaseInteractor = OSLog(subsystem: subsystem, category: "firebase_interactor")
}
