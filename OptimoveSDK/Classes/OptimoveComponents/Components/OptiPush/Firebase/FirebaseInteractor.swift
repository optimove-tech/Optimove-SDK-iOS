//  Copyright © 2017 Optimove. All rights reserved.

import FirebaseCore
import FirebaseMessaging
import Foundation
import os.log
import OptimoveCore

protocol OptimoveMbaasRegistrationHandling: class {
    func handleRegistrationTokenRefresh(token: String)
}

final class FirebaseInteractor: NSObject {

    private let networking: FirebaseInteractorNetworking
    private var storage: OptimoveStorage
    private var appController: FirebaseOptions?
    private var clientServiceOptions: FirebaseOptions?
    private var APNSToken: Data?
    private weak var delegate: OptimoveMbaasRegistrationHandling?

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
        Logger.debug("OptiPush: Setup Firebase started.")

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

        Messaging.messaging().delegate = self

        if let token = Messaging.messaging().fcmToken {
            registerIfTokenChanged(updatedFcmToken: token)
        }
        Logger.debug("OptiPush: Setup Firebase finished.")
    }

    func handleRegistration(token: Data) {
        if  Messaging.messaging().fcmToken == nil {
            APNSToken = token
        } else {
            Messaging.messaging().apnsToken = token
            APNSToken = nil
        }
    }

    func optimoveReceivedRegistrationToken(_ fcmToken: String) {
        if storage.isClientHasFirebase {
            guard storage.defaultFcmToken != fcmToken else {
                Logger.debug("OptiPush: the FCM token is not new, no need to refresh.")
                Logger.debug("OptiPush: 🚀 FCM token OLD: \(storage.fcmToken ?? "")")
                return
            }
            guard let optimoveAppSenderId = self.appController?.gcmSenderID else {
                Logger.debug("OptiPush: App controller not configure.")
                return
            }
            retreiveFcmToken(for: optimoveAppSenderId) { [weak self] (token) in
                Logger.debug("OptiPush: 🚀 FCM token NEW: \(token)")
                self?.delegate?.handleRegistrationTokenRefresh(token: token)
                self?.storage.defaultFcmToken = fcmToken
            }
        } else {
            Logger.debug("OptiPush: 🚀 FCM token for app controller: \(fcmToken)")
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
                case .success:
                    os_log(
                        "Subscribed topic '%{private}@' successful.",
                        log: OSLog.firebaseInteractor,
                        type: .info,
                        topic
                    )
                    OptimoveTopicsUserDefaults.topics?.set(true, forKey: "optimove_\(topic)")
                    didSucceed?(true)
                case let .failure(error):
                    Logger.error(error.localizedDescription)
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
                case .success:
                    os_log(
                        "Unsubscribed topic '%{private}@' successful.",
                        log: OSLog.firebaseInteractor,
                        type: .info,
                        topic
                    )
                    OptimoveTopicsUserDefaults.topics?.removeObject(forKey: "optimove_\(topic)")
                    didSucceed?(true)
                case let .failure(error):
                    Logger.error(error.localizedDescription)
                    didSucceed?(false)
                }
            }
        }
    }

}

extension FirebaseInteractor: MessagingDelegate {

    func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String) {
        registerIfTokenChanged(updatedFcmToken: fcmToken)
        if let token = APNSToken {
            Messaging.messaging().apnsToken = token
            APNSToken = nil
        }
    }

    func messaging(_ messaging: Messaging, didReceive remoteMessage: MessagingRemoteMessage) {

    }

}

private extension FirebaseInteractor {

    func setupAppController(_ appController: FirebaseOptions) {
        if FirebaseApp.app() != nil {
            Logger.warn("OptiPush: Hosted Firebase detected.")
            FirebaseApp.configure(
                name: "appController",
                options: appController
            )
            storage.isClientHasFirebase = true
        } else {
            Logger.warn("OptiPush: Hosted Firebase not detected.")
            storage.isClientHasFirebase = false
            FirebaseApp.configure(options: appController)
        }
    }

    func setupSdkController(_ clientServiceOptions: FirebaseOptions) {
        FirebaseApp.configure(name: "sdkController", options: clientServiceOptions)
    }

    func registerIfTokenChanged(updatedFcmToken: String) {
        if isNewFcmToken(receivedToken: updatedFcmToken) {
            optimoveReceivedRegistrationToken(updatedFcmToken)
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
            if let error = error {
                Logger.error("OptiPush: could not retreive dedicated FCM token. Reason: \(error.localizedDescription).")
            }
            if let token = token {
                completion(token)
            } else {
                Logger.error("OptiPush: Missed FCM token.")
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
