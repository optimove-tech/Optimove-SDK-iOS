
//  Optipush.swift
//  iOS-SDK
//
//  Created by Mobile Developer Optimove on 04/09/2017.
//  Copyright © 2017 Optimove. All rights reserved.
//

import UIKit
import UserNotifications

final class Optipush
{
    //MARK: - Variables
    var firebaseInteractor: FirebaseInteractor
    var registrar: Registrar
    
    //MARK: - Constructor
    init?(from json:[String:Any],clientHasFirebase:Bool,initializationDelegate: ComponentInitializationDelegate)
    {
        guard let mobileConfig = json[Keys.Configuration.mobile.rawValue] as? [String: Any],
            let optipushConfig = mobileConfig[Keys.Configuration.optipushMetaData.rawValue] as? [String: Any],
            let optipushMetaData = Parser.parseOptipushMetaData(from: optipushConfig),
            let firebaseConfig = mobileConfig[Keys.Configuration.firebaseProjectKeys.rawValue] as? [String: Any],
            let firebaseMetaData = Parser.parseFirebaseKeys(from: firebaseConfig),
            let clientFirebaseConfig = mobileConfig[Keys.Configuration.clientServiceProjectKeys.rawValue] as? [String: Any],
            let clientFirebaseMetaData = Parser.parseFirebaseKeys(from: clientFirebaseConfig,isClientService: true)
            else
        {
            Optimove.sharedInstance.logger.severe("Failed to parse optipush metadata")
            
            initializationDelegate.didFailInitialization(of: .optiPush, rootCause: .optipushComponentUnavailable)
            return nil
        }
        firebaseInteractor = FirebaseInteractor(clientHasFirebase: clientHasFirebase)
        registrar = Registrar(optipushMetaData: optipushMetaData)
        let firebaseSuccess = self.firebaseInteractor.setupFirebase(from: firebaseMetaData,
                                                                        clientFirebaseMetaData: clientFirebaseMetaData,
                                                                        delegate:self)
        if !firebaseSuccess
        {
            initializationDelegate.didFailInitialization(of: .optiPush, rootCause: .error)
            return nil
        }
        Optimove.sharedInstance.logger.debug("OptiPush initialization succeed")
        
    }
    
    //MARK: - Internal methods
    func application(didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data)
    {
        firebaseInteractor.handleRegistration(token:deviceToken)
    }
   
   
    
    func subscribeToTestMode()
    {
        firebaseInteractor.subscribeTestMode()
    }
    
    func unsubscribeFromTestMode()
    {
        firebaseInteractor.unsubscribeTestMode()
    }
    
    //MARK: - Private Methods
    
    func enableNotifications()
    {
        Optimove.sharedInstance.logger.debug("Ask for user permission to present notifications")
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert,.sound])
        { (granted, error) in
            DispatchQueue.main.async
            {
                Optimove.sharedInstance.logger.debug("register for remote  notifications")
                Optimove.sharedInstance.logger.debug("notification authorization response: \(granted)")
                self.handlenNotificationAuthorizationResponse(granted: granted,error: error)
            }
        }
        UIApplication.shared.registerForRemoteNotifications()
    }
    
    private func handlenNotificationAuthorizationResponse(granted: Bool, error: Error?)
    {
        if granted
        {
            Optimove.sharedInstance.logger.debug("Notification authorized by user")
            
            guard let isOptIn = UserInSession.shared.isOptIn
                else
            { //Opt in on first launch
                Optimove.sharedInstance.logger.debug("User Opt for first time")
                
                    UserInSession.shared.isOptIn = true
                    Optimove.sharedInstance.internalReport(event: OptipushOptIn())
                    return
            }
            if !isOptIn
            {
                Optimove.sharedInstance.logger.debug("SDK make opt OUT request")
                
                self.registrar.optIn()
            }
        }
        else
        {
            Optimove.sharedInstance.logger.debug("Notification unauthorized by user")
            
            guard let isOptIn = UserInSession.shared.isOptIn
                else
            {
                Optimove.sharedInstance.logger.debug("User Opt for first time")
                guard UserInSession.shared.fcmToken != nil
                    else
                {
                    
                    UserInSession.shared.isOptIn = false
                    return
                }
                
                if UserInSession.shared.isRegistrationSuccess
                {
                    Optimove.sharedInstance.logger.debug("SDK make opt OUT request")
                    
                    UserInSession.shared.isOptIn = false
                    self.registrar.optOut()
                }
                return
            }
            if isOptIn
            {
                if !(UserInSession.shared.hasRegisterJsonFile ?? false)
                {
                    Optimove.sharedInstance.logger.debug("SDK make opt OUT request")
                   
                    self.registrar.optOut()
                }
            }
            else {
                if !UserInSession.shared.isOptRequestSuccess {
                    self.registrar.optOut()
                }
            }
            
        }
    }
}

extension Optipush: MessageHandleProtocol
{
    //MARK: - Protocol conformance
    func handleRegistrationTokenRefresh(token:String)
    {
        print("fcmToken:\(token)")
        Optimove.sharedInstance.logger.debug("fcmToken:\(token)")
       
        guard let oldFCMToken = UserInSession.shared.fcmToken
            else
        {
            Optimove.sharedInstance.logger.debug("Client receive a token for the first time")
            UserInSession.shared.fcmToken = token
            registrar.register()
            return
        }
        
        if (token != oldFCMToken)
        {
            registrar.unregister()
            {
                UserInSession.shared.fcmToken = token
                self.registrar.register()
            }
        }
    }
}


