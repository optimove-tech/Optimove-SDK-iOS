
//  Optipush.swift
//  iOS-SDK
//
//  Created by Mobile Developer Optimove on 04/09/2017.
//  Copyright © 2017 Optimove. All rights reserved.
//

import Foundation
import UserNotifications

protocol OptipushServiceInfra {
    func subscribeToTopics(didSucceed: ((Bool)->())?)
    func unsubscribeFromTopics()
    func setupFirebase(from firebaseMetaData: FirebaseProjectKeys,
                       clientFirebaseMetaData:ClientsServiceProjectKeys,
                       delegate:OptimoveMbaasRegistrationHandling,
                       pushTopicsRegistrationEndpoint:String)
    func handleRegistration(token:Data)
    func optimoveReceivedRegistrationToken(_ fcmToken: String)

    func subscribeToTopic(topic:String,didSucceed: ((Bool)->())?)
    func unsubscribeFromTopic(topic:String, didSucceed: ((Bool)->())?)
}

final class OptiPush: OptimoveComponent
{
    //MARK: - Variables
    var metaData: OptipushMetaData!
    private var firebaseInteractor: OptipushServiceInfra
    private var registrar: RegistrationProtocol?

    init(deviceStateMonitor: OptimoveDeviceStateMonitor, infrastructure: OptipushServiceInfra = FirebaseInteractor()) {
        self.firebaseInteractor = infrastructure
        super.init(deviceStateMonitor: deviceStateMonitor)
    }
    
    override func performInitializationOperations()
    {
        if RunningFlagsIndication.isComponentRunning(.optiPush) {
            self.retryFailedMbaasOperations()
            self.optInOutIfNeeded()
            firebaseInteractor.subscribeToTopics(didSucceed: nil)
        }
    }
    
    //MARK: - Internal methods
    func setup(firebaseMetaData:FirebaseProjectKeys,
               clientFirebaseMetaData:ClientsServiceProjectKeys,
               optipushMetaData:OptipushMetaData)
    {
        registrar = Registrar(optipushMetaData: optipushMetaData)
        firebaseInteractor.setupFirebase(from: firebaseMetaData,
                                         clientFirebaseMetaData: clientFirebaseMetaData,
                                         delegate: self,
                                         pushTopicsRegistrationEndpoint: optipushMetaData.pushTopicsRegistrationEndpoint)
    }
    
    func application(didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data)
    {
        firebaseInteractor.handleRegistration(token:deviceToken)
    }
    
    func subscribeToTopic(topic:String, didSucceed: ((Bool)->())?  = nil)
    {
        if isEnable {
            firebaseInteractor.subscribeToTopic(topic:topic, didSucceed: didSucceed)
        } else {
            didSucceed?(false)
        }
    }
    func unsubscribeFromTopic(topic:String, didSucceed:  ((Bool)->())? = nil)
    {
        if isEnable {
            firebaseInteractor.unsubscribeFromTopic(topic: topic, didSucceed: didSucceed)
        } else {
          didSucceed?(false)
        }
    }
    
    func performRegistration()
    {
//        if OptimoveUserDefaults.shared.fcmToken != nil {
            registrar?.register()
//        }
    }
}

extension OptiPush: OptimoveMbaasRegistrationHandling
{
    //MARK: - Protocol conformance
    func handleRegistrationTokenRefresh(token: String)
    {
        guard let oldFCMToken = OptimoveUserDefaults.shared.fcmToken else {
            handleFcmTokenReceivedForTheFirstTime(token)
            return
        }
        
        if (token != oldFCMToken) {
            registrar?.unregister { (success) in
                if success {
                    self.updateFcmTokenWith(token)
                    self.performRegistration()
                    self.firebaseInteractor.subscribeToTopics(didSucceed: nil)
                } else {
                    self.updateFcmTokenWith(token)
                }
            }
        }
    }
    
    func didReceiveFirebaseRegistrationToken(fcmToken:String)
    {
        firebaseInteractor.optimoveReceivedRegistrationToken(fcmToken)
    }
   
    private func handleFcmTokenReceivedForTheFirstTime(_ token: String)
    {
        OptiLogger.debug("Client receive a token for the first time")
        OptimoveUserDefaults.shared.fcmToken = token
        performRegistration()
        firebaseInteractor.subscribeToTopics(didSucceed: nil)
    }
    
    private func updateFcmTokenWith(_ fcmToken:String)
    {
        OptimoveUserDefaults.shared.fcmToken = fcmToken
    }

    private func retryFailedMbaasOperations()
    {
        registrar?.retryFailedOperationsIfExist()
    }
}

extension OptiPush
{
    private func optInOutIfNeeded()
    {
        guard OptimoveUserDefaults.shared.isOptRequestSuccess else {return}
        deviceStateMonitor.getStatus(of: .userNotification) { (granted) in
            if granted {
                self.handleNotificationAuthorized()
            } else {
                self.handleNotificationRejection()
            }
        }
    }
    private func handleNotificationAuthorizedAtFirstLaunch()
    {
        OptiLogger.debug("User Opt for first time")
        OptimoveUserDefaults.shared.isMbaasOptIn = true
    }
    private func handleNotificationAuthorized()
    {
        OptiLogger.debug("Notification authorized by user")
        guard let isOptIn = OptimoveUserDefaults.shared.isMbaasOptIn else
        { //Opt in on first launch
            handleNotificationAuthorizedAtFirstLaunch()
            return
        }
        if !isOptIn
        {
            OptiLogger.debug("SDK make opt in request")
            self.registrar?.optIn()
            
        }
    }
    private func handleNotificationRejection()
    {
        OptiLogger.debug("Notification unauthorized by user")
        
        guard let isOptIn = OptimoveUserDefaults.shared.isMbaasOptIn else {
            //Opt out on first launch
            handleNotificationRejectionAtFirstLaunch()
            return
        }
        if isOptIn {
            OptiLogger.debug("SDK make opt OUT request")
            registrar?.optOut()
            OptimoveUserDefaults.shared.isMbaasOptIn = false
        }
    }
    private func handleNotificationRejectionAtFirstLaunch()
    {
        OptiLogger.debug("User Opt out at first launch")
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
