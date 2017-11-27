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
    let delegate: MessageHandleProtocol!
    
    //MARK: Constructors
    init(messageHandler:MessageHandleProtocol)
    {
        delegate = messageHandler
    }
    
    //MARK: - static methods
     func setupFirebase(from firebaMetaData: FirebaseMetaData,
                              clientFirebaseMetaData:FirebaseMetaData,
                              clientHasFirebase:Bool)
    {
        DispatchQueue.main.async
            {
            guard let secondaryOptions = self.generateOptimoveSecondaryOptions(from: firebaMetaData),
            let clientServiceOptions = self.generateOptimoveSecondaryOptions(from: clientFirebaseMetaData)
                else {return}
            
                if !clientHasFirebase
                {
                    FirebaseApp.configure(options: secondaryOptions)
                }
                else
                {
                    FirebaseApp.configure(name: "appController",
                                          options: secondaryOptions)
                }
            FirebaseApp.configure(name: "sdkController",
                                  options:clientServiceOptions)
        }
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
    
    func getDynamicLinks(from shortUrl:URL?,
                         completionHandler:@escaping (DynamicLinkComponents?) -> Void)
    {
        guard let dynamicLinks = DynamicLinks.dynamicLinks(),
            let shortUrl = shortUrl
            else
        {
            completionHandler(nil)
            return
        }
        dynamicLinks.handleUniversalLink(shortUrl)
        { (deepLink, error) in
            
            guard let screenName = deepLink?.url?.lastPathComponent,
                let query = deepLink?.url?.queryParameters
                else
            {
                completionHandler(nil)
                return
            }
            completionHandler(DynamicLinkComponents(screenName: screenName, query: query))
        }
    }
}
extension FirebaseInteractor:MessagingDelegate
{
    func messaging(_ messaging: Messaging,
                   didRefreshRegistrationToken fcmToken: String)
    {
        delegate.handleRegistrationTokenRefresh(token:fcmToken)
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
        Messaging.messaging().delegate = self
        Messaging.messaging().apnsToken = token
        subscribeToTopics()
    }
}
