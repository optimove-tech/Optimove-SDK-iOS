//
//  Initializer.swift
//  OptimoveSDKDev
//
//  Created by Mobile Developer Optimove on 13/09/2017.
//  Copyright © 2017 Optimove. All rights reserved.
//

import Foundation


protocol ComponentInitializationDelegate
{
    func didFinishInitialization(of component:Component, withState state:State.Component)
    func didFailInitialization(of component:Component,rootCause:OptimoveError)
}

class OptimoveComponentsInitializer
{
    //MARK: - Private Variables
    fileprivate var numOfInitializedObjects:Int
    
    //MARK: - Internal variables
    var initializationErrors : [OptimoveError]
    
    //MARK: - Constants  
    let completionHandler: ResultBlockWithErrors
    let clientHasFirebase: Bool
    
    
    //MARK: - Constructors
    init( isClientFirebaseExist: Bool,
         completionHandler:@escaping ResultBlockWithErrors)
    {
        LogManager.reportToConsole("Start OptimoveComponentInitializer init")
        initializationErrors    = []
        self.clientHasFirebase  = isClientFirebaseExist
        numOfInitializedObjects = 0
        self.completionHandler  = completionHandler
        LogManager.reportToConsole("Finish OptimoveComponentInitializer init")
    }
    
    //MARK: - Internal Methods
    func startInitialization()
    {
        LogManager.reportToConsole("Start Optimove component initialization")
        guard isInternetAvailable()
            else
        {
            LogManager.reportFailureToConsole("No Internet connection")
            completionHandler([.noNetwork])
            return
        }
        NetworkManager.getInitConfigurations(token: UserInSession.shared.tenantToken!, version: Verison!)
        { (data, error) in
            guard error == nil else
            {
                if let error = error as? OptimoveError
                {
                    self.initializationErrors.append(error )
                }
                return
            }
            if let json = data as? [String: Any]
            {
                DispatchQueue.main.async
                    {
                        UserInSession.shared.tenantID = json[Keys.Configuration.tenantId.rawValue] as? Int
                        Optimove.sharedInstance.eventValidator = EventValidator()
                        Optimove.sharedInstance.optitrack = OptiTrack.newIntsance(from: json,initializationDelegate: self)
                        Optimove.sharedInstance.optiPush = Optipush.newIntsance(from: json,
                                                                                clientHasFirebase: self.clientHasFirebase,
                                                                                initializationDelegate: self)
                        let validatorState:State.Component = Optimove.sharedInstance.eventValidator!.loadConfigs(from: json) ? .active : .inactive
                        Optimove.sharedInstance.monitor.update(component: Component.validator,
                                                               state: validatorState)
                }
            }
        }
    }
    
    //MARK: - Private Methods
    fileprivate func notifyCompponentFinish()
    {
        numOfInitializedObjects += 1
        if numOfInitializedObjects == 2
        {
            completionHandler(initializationErrors)
        }
    }
}
    
extension OptimoveComponentsInitializer : ComponentInitializationDelegate
{
    func didFinishInitialization(of component:Component, withState  state:State.Component)
    {
        Optimove.sharedInstance.monitor.update(component: component, state: state)
        notifyCompponentFinish()
    }
    func didFailInitialization(of component:Component,rootCause:OptimoveError)
    {
        initializationErrors.append(rootCause)
        Optimove.sharedInstance.monitor.update(component: component, state: .inactive)
        notifyCompponentFinish()
    }
}




