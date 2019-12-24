//  Copyright © 2017 Optimove. All rights reserved.

import FirebaseCore
import FirebaseMessaging
import Foundation
import OptimoveCore

final class FirebaseInteractor: PushServiceProvider {

    private let networking: FirebaseInteractorNetworking
    private var storage: OptimoveStorage
    private var appController: FirebaseOptions?
    private var clientServiceOptions: FirebaseOptions?

    init(storage: OptimoveStorage,
         networking: FirebaseInteractorNetworking,
         optipush: OptipushConfig) {
        self.storage = storage
        self.networking = networking
        setup(optipush: optipush)
    }

    private func setup(optipush: OptipushConfig) {
        Logger.debug("OptiPush: Setup Firebase started.")

        let firebaseMetaData = optipush.firebaseProjectKeys
        let clientFirebaseMetaData = optipush.clientsServiceProjectKeys
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

        DispatchQueue.main.async {
            if let token = Messaging.messaging().fcmToken {
                self.registerIfTokenChanged(updatedFcmToken: token)
            } else {
                NotificationCenter.default.addObserver(
                    forName: NSNotification.Name.MessagingRegistrationTokenRefreshed,
                    object: nil,
                    queue: .main
                ) { (_) in
                    if let fcmToken = Messaging.messaging().fcmToken {
                        self.onTokenRenew(fcmToken: fcmToken)
                    }
                }
            }
            Logger.debug("OptiPush: Setup Firebase finished.")
        }
    }

    // MARK: - FirebaseProvider

    func handleRegistration(apnsToken: Data) 
        DispatchQueue.main.async {
            if let fcmToken = Messaging.messaging().fcmToken {
                self.onTokenRenew(fcmToken: fcmToken)
            }
        }
    }

    func optimoveReceivedRegistrationToken(_ fcmToken: String) {
        let setAPNsTokenToFirebase = { [weak self] in
            if let apnsToken = self?.storage.apnsToken {
                Messaging.messaging().apnsToken = apnsToken
            }
        }
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
            retreiveFcmToken(for: optimoveAppSenderId) { [weak self] (optimoveFCMToken) in
                setAPNsTokenToFirebase()
                Logger.debug("OptiPush: 🚀 FCM token NEW: \(optimoveFCMToken)")
                self?.storage.fcmToken = optimoveFCMToken
                self?.storage.defaultFcmToken = optimoveFCMToken
            }
        } else {
            setAPNsTokenToFirebase()
            Logger.debug("OptiPush: 🚀 FCM token for app controller: \(fcmToken)")
            self.storage.fcmToken = fcmToken
        }
    }

    func subscribeToTopic(topic: String) {
        if !storage.isClientHasFirebase {
            DispatchQueue.main.async {
                Messaging.messaging().subscribe(toTopic: topic) { (error) in
                    if let error = error {
                        Logger.error(error.localizedDescription)
                    } else {
                        Logger.debug("Subscribed topic \(topic) successful.")
                    }
                }
            }
        } else {
            networking.subscribe(topic: topic) { (result) in
                switch result {
                case .success:
                    Logger.debug("Subscribed topic \(topic) successful.")
                    OptimoveTopicsUserDefaults.topics?.set(true, forKey: "optimove_\(topic)")
                case let .failure(error):
                    Logger.error(error.localizedDescription)
                    OptimoveTopicsUserDefaults.topics?.set(false, forKey: "optimove_\(topic)")
                }
            }
        }
    }

    func unsubscribeFromTopic(topic: String) {
        if !storage.isClientHasFirebase {
            DispatchQueue.main.async {
                Messaging.messaging().unsubscribe(fromTopic: topic) { (error) in
                    if let error = error {
                        Logger.error(error.localizedDescription)
                    } else {
                        Logger.debug("Unsubscribed topic \(topic) successful.")
                    }
                }
            }
        } else {
            networking.unsubscribe(topic: topic) { (result) in
                switch result {
                case .success:
                    Logger.debug("Unsubscribed topic \(topic) successful.")
                    OptimoveTopicsUserDefaults.topics?.removeObject(forKey: "optimove_\(topic)")
                case let .failure(error):
                    Logger.error(error.localizedDescription)
                }
            }
        }
    }

}

private extension FirebaseInteractor {

    func setupAppController(_ appController: FirebaseOptions) {
        DispatchQueue.main.async {
            if FirebaseApp.app() != nil {
                Logger.warn("OptiPush: Hosted Firebase detected.")
                FirebaseApp.configure(
                    name: "appController",
                    options: appController
                )
                self.storage.isClientHasFirebase = true
            } else {
                Logger.warn("OptiPush: Hosted Firebase not detected.")
                self.storage.isClientHasFirebase = false
                FirebaseApp.configure(options: appController)
            }
        }
    }

    func setupSdkController(_ clientServiceOptions: FirebaseOptions) {
        DispatchQueue.main.async {
            FirebaseApp.configure(name: "sdkController", options: clientServiceOptions)
        }
    }

    func onTokenRenew(fcmToken: String) {
        registerIfTokenChanged(updatedFcmToken: fcmToken)
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
        DispatchQueue.main.async {
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
    }

}
