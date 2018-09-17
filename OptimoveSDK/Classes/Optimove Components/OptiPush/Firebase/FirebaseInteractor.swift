//
//  FirebaseInteractor.swift
//  OptimoveSDK
//
//  Created by Mobile Developer Optimove on 26/09/2017.
//  Copyright © 2017 Optimove. All rights reserved.
//

import Foundation
import FirebaseCore
import FirebaseMessaging


protocol OptimoveMbaasRegistrationHandling:class
{
    func handleRegistrationTokenRefresh(token:String)
}

class FirebaseInteractor:NSObject
{
    //MARK: - Properties
    weak var delegate: OptimoveMbaasRegistrationHandling?
    var appController: FirebaseOptions?
    var clientServiceOptions:FirebaseOptions?
    
    var pushTopicsRegistrationEndpoint:String
    
    //MARK: Constructors
    override init()
    {
        pushTopicsRegistrationEndpoint = ""
    }
    
    //MARK: - static methods
    private func setupAppController(_ appController: FirebaseOptions) {
        if OptimoveUserDefaults.shared.isClientHasFirebase {
            OptiLogger.debug("user indicate it uses hosted firebase")
            FirebaseApp.configure(name: "appController",
                                  options: appController)
        } else {
            OptiLogger.debug("user indicate not hosted firebase")
            FirebaseApp.configure(options: appController)
        }
    }
    
    private func setupSdkController(_ clientServiceOptions: FirebaseOptions)
    {
        FirebaseApp.configure(name: "sdkController", options:clientServiceOptions)
    }
    
    private func setMessaginDelegate()
    {
        if !OptimoveUserDefaults.shared.isClientUseFirebaseMessaging
        {
            Messaging.messaging().delegate = self
        }
    }
    
    func setupFirebase(from firebaseMetaData: FirebaseProjectKeys,
                       clientFirebaseMetaData:ClientsServiceProjectKeys,
                       delegate:OptimoveMbaasRegistrationHandling,
                       endPointForTopics:String)
    {
        setMessaginDelegate()
        OptiLogger.debug("Setup firebase")
        pushTopicsRegistrationEndpoint = endPointForTopics
        self.delegate = delegate
        self.appController = FirebaseOptionsBuilder()
            .set(appId: firebaseMetaData.appid)
            .set(dbUrl: firebaseMetaData.dbUrl)
            .set(projectId: firebaseMetaData.projectId)
            .set(senderId: firebaseMetaData.senderId)
            .set(webApiKey: firebaseMetaData.webApiKey)
            .set(storageBucket: firebaseMetaData.storageBucket)
            .build()
        self.clientServiceOptions = FirebaseOptionsBuilder()
            .set(appId: clientFirebaseMetaData.appid)
            .set(dbUrl: clientFirebaseMetaData.dbUrl)
            .set(projectId: clientFirebaseMetaData.projectId)
            .set(senderId: clientFirebaseMetaData.senderId)
            .set(webApiKey: clientFirebaseMetaData.webApiKey)
            .set(storageBucket: clientFirebaseMetaData.storageBucket)
            .build()
        guard let appController = self.appController,
            let clientServiceOptions = self.clientServiceOptions
            else {return }
        
        setupAppController(appController)
        setupSdkController(clientServiceOptions)
        if OptimoveUserDefaults.shared.fcmToken == nil && Messaging.messaging().fcmToken != nil{
            optimoveReceivedRegistrationToken(Messaging.messaging().fcmToken!)
        }
        
        
        OptiLogger.debug("firebase finish setup")
    }
    
    //MARK: - Private Methods
    private func isNewFcmToken(receivedToken received:String) -> Bool
    {
        if let oldFCM = OptimoveUserDefaults.shared.fcmToken
        {
            return received != oldFCM
        }
        return true
    }
}

extension FirebaseInteractor:MessagingDelegate
{
    func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String)
    {
        optimoveReceivedRegistrationToken(fcmToken)
    }
    
    func retreiveFcmToken(for senderId: String, completion: @escaping (String) -> Void)
    {
        Messaging.messaging().retrieveFCMToken(forSenderID: senderId)
        { (token, error) in
            guard error == nil else {
                OptiLogger.debug("could not retreive dedicated fcm token with error \(error!.localizedDescription)")
                return
            }
            if let token = token {
                completion(token)
            }
        }
    }
    
    func optimoveReceivedRegistrationToken(_ fcmToken: String)
    {
        if OptimoveUserDefaults.shared.isClientHasFirebase {
            guard OptimoveUserDefaults.shared.defaultFcmToken != fcmToken else {
                OptiLogger.debug("fcm token is not new, no need to refresh")
                return
            }
            guard let optimoveAppSenderId = self.appController?.gcmSenderID else {
                OptiLogger.debug("app controller not configure")
                return
            }
            OptiLogger.debug("old fcm: \(String(describing: OptimoveUserDefaults.shared.fcmToken ?? ""))")
            retreiveFcmToken(for: optimoveAppSenderId) {[unowned self] (token) in
                OptiLogger.debug("new fcm: \(String(describing: token))")
                self.delegate?.handleRegistrationTokenRefresh(token: token)
                OptimoveUserDefaults.shared.defaultFcmToken = fcmToken
            }
        } else {
            OptiLogger.debug("fcm for app controller:\(fcmToken)")
            self.delegate?.handleRegistrationTokenRefresh(token: fcmToken)
        }
    }
    
    private func getMongoTypeBundleId() -> String
    {
        return Bundle.main.bundleIdentifier?.setAsMongoKey() ?? ""
    }
    
    func subscribeToTopics(didSucceed: ((Bool)->())? = nil)
    {
        let dict = OptimoveTopicsUserDefaults.topics?.dictionaryRepresentation()
        dict?.forEach { (key,value) in
            if key.hasPrefix("optimove_") {
                subscribeToTopic(topic: key.deletingPrefix("optimove_"))
            }
        }
        subscribeToTopic(topic: "optipush_general")
        subscribeToTopic(topic: "ios")
        subscribeToTopic(topic: getMongoTypeBundleId())
    }
    func unsubscribeFromTopics()
    {
        let dict = OptimoveTopicsUserDefaults.topics?.dictionaryRepresentation()
        dict?.forEach { (key,value) in
            if key.hasPrefix("optimove_") {
                unsubscribeFromTopic(topic: key.deletingPrefix("optimove_"))
            }
        }
    }
    
    func subscribeToTopic(topic:String,didSucceed: ((Bool)->())? = nil)
    {
        if !OptimoveUserDefaults.shared.isClientHasFirebase {
            Messaging.messaging().subscribe(toTopic: topic) { (error) in
                if error != nil {
                    didSucceed?(false)
                } else {
                    didSucceed?(true)
                }
            }
        } else {
            guard let fcm = OptimoveUserDefaults.shared.fcmToken else {return }
            let endPoint = pushTopicsRegistrationEndpoint + "registerClientToTopics"
            let urlEndpoint = URL(string: endPoint)!
            let json = buildTopicRegistrationJson(fcm, [topic])
            NetworkManager.post(toUrl: urlEndpoint, json: json) { (data, error) in
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
    
    func unsubscribeFromTopic(topic:String, didSucceed: ((Bool)->())? = nil)
    {
        if !OptimoveUserDefaults.shared.isClientHasFirebase {
            Messaging.messaging().unsubscribe(fromTopic: topic) { (error) in
                if error != nil {
                    didSucceed?(false)
                } else {
                    didSucceed?(true)
                }
            }
        } else {
            guard let fcm = OptimoveUserDefaults.shared.fcmToken else {return }
            let endPoint = pushTopicsRegistrationEndpoint + "unregisterClientFromTopics"
            let urlEndpoint = URL(string: endPoint)!
            let json = buildTopicRegistrationJson(fcm, [topic])
            
            NetworkManager.post(toUrl: urlEndpoint, json: json) { (data, error) in
                guard error == nil else {
                    didSucceed?(false)
                    return
                }
                OptimoveTopicsUserDefaults.topics?.removeObject(forKey: "optimove_\(topic)")
                didSucceed?(true)
            }
        }
    }
    
    func handleRegistration(token:Data)
    {
        Messaging.messaging().apnsToken = token
    }
    
    private func buildTopicRegistrationJson(_ fcmToken: String, _ topics: [String]) -> Data
    {
        var requestJsonData = [String: Any]()
        requestJsonData[Keys.Topics.fcmToken.rawValue] = fcmToken
        requestJsonData[Keys.Topics.topics.rawValue] = topics
        return try! JSONSerialization.data(withJSONObject: requestJsonData, options: .prettyPrinted)
    }
}
