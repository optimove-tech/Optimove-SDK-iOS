//
//  FirebaseInteractor.swift
//  OptimoveSDK
//
//  Created by Mobile Developer Optimove on 26/09/2017.
//  Copyright © 2017 Optimove. All rights reserved.
//

import Foundation
import Firebase

protocol MessageHandleProtocol
{
    func handleRegistrationTokenRefresh(token:String)
}

class FirebaseInteractor:NSObject
{
    //MARK: - Properties
    var delegate: MessageHandleProtocol!
    var clientHasFirebase:Bool
    var appController: FirebaseOptions?
    var clientServiceOptions:FirebaseOptions?
    //MARK: Constructors
    init(clientHasFirebase:Bool)
    {
        self.clientHasFirebase = clientHasFirebase
    }
    
    //MARK: - static methods
    func setupFirebase(from firebaMetaData: FirebaseMetaData,
                       clientFirebaseMetaData:FirebaseMetaData,
                       delegate:MessageHandleProtocol) -> Bool
    {
        
        Optimove.sharedInstance.logger.debug("Setup firebase")
        self.delegate = delegate
        self.appController = self.generateOptimoveSecondaryOptions(from: firebaMetaData)
        self.clientServiceOptions = self.generateOptimoveSecondaryOptions(from: clientFirebaseMetaData)
        guard let appController = self.appController,  let clientServiceOptions = self.clientServiceOptions
            else {return false}
        
        if !clientHasFirebase
        {
            Optimove.sharedInstance.logger.debug("user indicate not hosted firebase")
            if FirebaseApp.app() == nil {
                FirebaseApp.configure(options: appController)
            }
        }
        else
        {
            if FirebaseApp.app(name: "appController") == nil {
                FirebaseApp.configure(name: "appController",
                                      options: appController)
            }
        }
        if FirebaseApp.app(name: "sdkController") == nil {
            FirebaseApp.configure(name: "sdkController",
                                  options:clientServiceOptions)
        }
        Messaging.messaging().delegate = self
        
        if UserInSession.shared.userHasFirebase, UserInSession.shared.fcmToken == nil
        {
            if let optimoveSenderId = self.appController?.gcmSenderID
            {
                retreiveFcmToken(for: optimoveSenderId)
            }
        }
        Optimove.sharedInstance.logger.debug("firebase finish setup")
        return true
    }
    
    private func generateOptimoveSecondaryOptions(from firebaseKeys: FirebaseMetaData) -> FirebaseOptions?
    {
        guard let webApiKey = firebaseKeys.webApiKey,
            let appId = firebaseKeys.appId,
            let dbUrl = firebaseKeys.dbUrl,
            let senderId = firebaseKeys.senderId,
            let storageBucket = firebaseKeys.storageBucket,
            let projectId = firebaseKeys.projectId
            else { return nil }
        let appControllerOptions = FirebaseOptions.init(googleAppID: appId,
                                                        gcmSenderID: senderId)
        appControllerOptions.bundleID               = Bundle.main.bundleIdentifier!
        appControllerOptions.apiKey                 = webApiKey
        appControllerOptions.databaseURL            = dbUrl
        appControllerOptions.storageBucket          = storageBucket
        appControllerOptions.deepLinkURLScheme      = appControllerOptions.bundleID
        appControllerOptions.projectID              = projectId
        appControllerOptions.clientID               = "gibrish-firebase"
        
        return appControllerOptions
    }
    
    func isNewFcmToken(receivedToken received:String) -> Bool
    {
        if let oldFCM = UserInSession.shared.fcmToken
        {
            return received != oldFCM
        }
        return true
    }
}

extension FirebaseInteractor:MessagingDelegate
{
     func retreiveFcmToken(for senderId: String) {
        Messaging.messaging().retrieveFCMToken(forSenderID: senderId)
        { (token, error) in
            if let error = error
            {
                Optimove.sharedInstance.logger.severe("could not retreive dedicated fcm token with error \(error.localizedDescription)")
                
                return
            }
            if let token = token
            {
                self.finishTokenRegistrations(forToken: token)
            }
        }
    }
    
    func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String)
    {
        Optimove.sharedInstance.logger.debug("!!!didReceiveRegistrationToken!!!")
        if UserInSession.shared.userHasFirebase
        {
            if isNewFcmToken(receivedToken: fcmToken)
            {
                if let optimoveSenderId = self.appController?.gcmSenderID
                {
                    Optimove.sharedInstance.logger.debug("retreived token for sender ID")
                    Optimove.sharedInstance.logger.debug("old fcm: \(String(describing: UserInSession.shared.fcmToken))")
                    retreiveFcmToken(for: optimoveSenderId)
                    Optimove.sharedInstance.logger.debug("new fcm: \(String(describing: UserInSession.shared.fcmToken))")
                }
            }
            else
            {
                Optimove.sharedInstance.logger.debug("fcm token is not new")
            }
        }
        else
        {
            finishTokenRegistrations(forToken: fcmToken)
        }
    }
    
    func finishTokenRegistrations(forToken token:String)
    {
        self.subscribeToTopics()
        self.delegate.handleRegistrationTokenRefresh(token: token)
    }
    
    fileprivate func getMongoTypeBundleId() -> String
    {
        return Bundle.main.bundleIdentifier?.setAsMongoKey() ?? ""
    }
    
    fileprivate func subscribeToTopics()
    {
        Messaging.messaging().subscribe(toTopic: "optipush_general")
        Messaging.messaging().subscribe(toTopic: "ios")
        Messaging.messaging().subscribe(toTopic: getMongoTypeBundleId() )
    }
    
    func subscribeTestMode()
    {
        if let bundleID = Bundle.main.bundleIdentifier
        {
            Messaging.messaging().subscribe(toTopic: "test_" + bundleID)
        }
    }
    
    func unsubscribeTestMode()
    {
        if let bundleID = Bundle.main.bundleIdentifier
        {
            Messaging.messaging().unsubscribe(fromTopic: "test_" + bundleID)
        }
    }
    func handleRegistration(token:Data)
    {
        Messaging.messaging().apnsToken = token
        
    }
}
