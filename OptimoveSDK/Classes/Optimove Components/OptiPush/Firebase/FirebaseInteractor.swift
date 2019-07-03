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

protocol OptimoveMbaasRegistrationHandling: class {
    func handleRegistrationTokenRefresh(token: String)
}

class FirebaseInteractor: NSObject, OptipushServiceInfra {
    // MARK: - Properties
    weak var delegate: OptimoveMbaasRegistrationHandling?
    var appController: FirebaseOptions?
    var clientServiceOptions: FirebaseOptions?
    var pushTopicsRegistrationEndpoint: String

    // MARK: Constructors
    override init() {
        pushTopicsRegistrationEndpoint = ""
    }

    private func setupAppController(_ appController: FirebaseOptions) {
        if FirebaseApp.app() != nil {
            OptiLoggerMessages.logUserUseAutonomousFirebase(logModule: "OptiPush")
            FirebaseApp.configure(
                name: "appController",
                options: appController
            )
            OptimoveUserDefaults.shared.isClientHasFirebase = true
        } else {
            OptiLoggerMessages.logUserNotUseOwnFirebase()
            OptimoveUserDefaults.shared.isClientHasFirebase = false
            FirebaseApp.configure(options: appController)
        }
    }

    private func setupSdkController(_ clientServiceOptions: FirebaseOptions) {
        FirebaseApp.configure(name: "sdkController", options: clientServiceOptions)
    }

    fileprivate func registerIfTokenChanged(updatedFcmToken: String?) {
        let isTokenNew = updatedFcmToken != nil && OptimoveUserDefaults.shared.fcmToken != updatedFcmToken
        if isTokenNew {
            optimoveReceivedRegistrationToken(updatedFcmToken!)
        }
    }

    func setupFirebase(
        from firebaseMetaData: FirebaseProjectKeys,
        clientFirebaseMetaData: ClientsServiceProjectKeys,
        delegate: OptimoveMbaasRegistrationHandling,
        pushTopicsRegistrationEndpoint: String
    ) {
        OptiLoggerMessages.logSetupFirebase()

        self.pushTopicsRegistrationEndpoint = pushTopicsRegistrationEndpoint.last == "/"
            ? pushTopicsRegistrationEndpoint : "\(pushTopicsRegistrationEndpoint)/"
        self.delegate = delegate
        self.appController = FirebaseOptionsBuilder().set(appId: firebaseMetaData.appid).set(
            dbUrl: firebaseMetaData.dbUrl
        ).set(projectId: firebaseMetaData.projectId).set(senderId: firebaseMetaData.senderId).set(
            webApiKey: firebaseMetaData.webApiKey
        ).set(storageBucket: firebaseMetaData.storageBucket).build()
        self.clientServiceOptions = FirebaseOptionsBuilder().set(appId: clientFirebaseMetaData.appid).set(
            dbUrl: clientFirebaseMetaData.dbUrl
        ).set(projectId: clientFirebaseMetaData.projectId).set(senderId: clientFirebaseMetaData.senderId).set(
            webApiKey: clientFirebaseMetaData.webApiKey
        ).set(storageBucket: clientFirebaseMetaData.storageBucket).build()
        guard let appController = self.appController,
            let clientServiceOptions = self.clientServiceOptions
        else { return }

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

    // MARK: - Private Methods
    private func isNewFcmToken(receivedToken received: String) -> Bool {
        if let oldFCM = OptimoveUserDefaults.shared.fcmToken {
            return received != oldFCM
        }
        return true
    }
}

extension FirebaseInteractor: MessagingDelegate {
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

    func optimoveReceivedRegistrationToken(_ fcmToken: String) {
        if OptimoveUserDefaults.shared.isClientHasFirebase {
            guard OptimoveUserDefaults.shared.defaultFcmToken != fcmToken else {
                OptiLoggerMessages.logFcmTokenNotNew()
                return
            }
            guard let optimoveAppSenderId = self.appController?.gcmSenderID else {
                OptiLoggerMessages.logAppControllerNotConfigure()
                return
            }
            OptiLoggerMessages.logOldFcmToken(token: String(describing: OptimoveUserDefaults.shared.fcmToken ?? ""))
            retreiveFcmToken(for: optimoveAppSenderId) { [unowned self] (token) in
                OptiLoggerMessages.logNewFcmToken(token: token)
                self.delegate?.handleRegistrationTokenRefresh(token: token)
                OptimoveUserDefaults.shared.defaultFcmToken = fcmToken
            }
        } else {
            OptiLoggerMessages.logFcmTokenForAppController(fcmToken: fcmToken)
            self.delegate?.handleRegistrationTokenRefresh(token: fcmToken)
        }
    }

    private func getMongoTypeBundleId() -> String {
        return Bundle.main.bundleIdentifier?.setAsMongoKey() ?? ""
    }

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

    func subscribeToTopic(topic: String, didSucceed: ((Bool) -> Void)? = nil) {
        if !OptimoveUserDefaults.shared.isClientHasFirebase {
            Messaging.messaging().subscribe(toTopic: topic) { (error) in
                if error != nil {
                    didSucceed?(false)
                } else {
                    didSucceed?(true)
                }
            }
        } else {
            guard let fcm = OptimoveUserDefaults.shared.fcmToken else { return }
            let endPoint = pushTopicsRegistrationEndpoint + "registerClientToTopics"
            let urlEndpoint = URL(string: endPoint)!
            let json = buildTopicRegistrationJson(fcm, [topic])
            NetworkManager.post(toUrl: urlEndpoint, json: json) { (_, error) in
                guard error == nil else {
                    OptimoveTopicsUserDefaults.topics?.set(false, forKey: "optimove_\(topic)")
                    didSucceed?(false)
                    return
                }
                OptimoveTopicsUserDefaults.topics?.set(true, forKey: "optimove_\(topic)")
                didSucceed?(true)
            }
        }
    }

    func unsubscribeFromTopic(topic: String, didSucceed: ((Bool) -> Void)? = nil) {
        if !OptimoveUserDefaults.shared.isClientHasFirebase {
            Messaging.messaging().unsubscribe(fromTopic: topic) { (error) in
                if error != nil {
                    didSucceed?(false)
                } else {
                    didSucceed?(true)
                }
            }
        } else {
            guard let fcm = OptimoveUserDefaults.shared.fcmToken else { return }
            let endPoint = pushTopicsRegistrationEndpoint + "unregisterClientFromTopics"
            let urlEndpoint = URL(string: endPoint)!
            let json = buildTopicRegistrationJson(fcm, [topic])

            NetworkManager.post(toUrl: urlEndpoint, json: json) { (_, error) in
                guard error == nil else {
                    didSucceed?(false)
                    return
                }
                OptimoveTopicsUserDefaults.topics?.removeObject(forKey: "optimove_\(topic)")
                didSucceed?(true)
            }
        }
    }

    func handleRegistration(token: Data) {
        Messaging.messaging().apnsToken = token
    }

    private func buildTopicRegistrationJson(_ fcmToken: String, _ topics: [String]) -> Data {
        var requestJsonData = [String: Any]()
        requestJsonData[OptimoveKeys.Topics.fcmToken.rawValue] = fcmToken
        requestJsonData[OptimoveKeys.Topics.topics.rawValue] = topics
        return try! JSONSerialization.data(withJSONObject: requestJsonData, options: .prettyPrinted)
    }
}
