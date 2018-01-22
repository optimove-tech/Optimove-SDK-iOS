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
    func didFinishInitialization(of component:Component)
    func didFailInitialization(of component:Component,rootCause:OptimoveError)
}

class OptimoveComponentsInitializer
{
    //MARK: - Private Variables
    fileprivate var numOfInitializedObjects:Int
    
    //MARK: - Internal variables
    var initializationErrors : [OptimoveError]
    
    //MARK: - Constants  
    //    let completionHandler: ResultBlockWithErrors
    let clientHasFirebase: Bool
    
   static let atomicBool = AtomicBool()
    

    //MARK: - Initializers
    init(isClientFirebaseExist: Bool)
    {
        Optimove.sharedInstance.logger.debug("Initialize OptimoveComponentInitializer")
        initializationErrors    = []
        self.clientHasFirebase  = isClientFirebaseExist
        numOfInitializedObjects = 0
    
        Optimove.sharedInstance.logger.debug("Finish OptimoveComponentInitializer initialization")
    }
    
    func start()
    {
        Optimove.sharedInstance.logger.error("Start Optimove component initialization")
        guard isInternetAvailable()
            else
        {
            Optimove.sharedInstance.logger.error("No Internet connection")
            
            finishSdkInit(with: [.noNetwork])
            return
        }
        if let tenantToken = UserInSession.shared.tenantToken, let version = Verison
        {
            NetworkManager.getInitConfigurations(token: tenantToken, version: version)
            { (data, error) in
                guard let data = data as? Data
                    else {
                        let error = error ?? OptimoveError.error
                        self.finishSdkInit(with: [error])
                        return
                    }
                
                Optimove.sharedInstance.logger.error("Parsing Configuration Meta Data")
                let parsedResponse = Parser.extractJSONFrom(data: data)
                if let error = parsedResponse.error
                {
                    Optimove.sharedInstance.logger.severe("Configuration Parsing failed")
                    self.finishSdkInit(with: [error])
                    return
                }
                if let json = parsedResponse.json
                {
                    if let data = try? JSONSerialization.data(withJSONObject: json, options:.prettyPrinted)
                    {
                        self.saveConfigurationToFile(data:data)
                    }
                    
                    Optimove.sharedInstance.logger.debug("Configuration Parsing succeeded")
                    UserInSession.shared.siteID = Parser.extractSiteIdFrom(json: json)
                    if OptimoveComponentsInitializer.atomicBool.compareAndSet(expected: false, value: true) {
                        self.setupOptimoveComponents(from: json)
                    }
                    else {
                        Optimove.sharedInstance.logger.debug("skipping remote initialization since already initialized")
                    }
                }
            }
        }
    }
    
    ///When the SDK is initialized by a push notification start the initialization from the local JSON file
    func startFromLocalConfigs()
    {
        let actionFile = "configuration_data.json"
        let actionURL = OptimoveFileManager.shared.optimoveSDKDirectory.appendingPathComponent(actionFile)
        do
        {
            let configData  = try? Data.init(contentsOf: actionURL)
            if let json = Parser.extractJSONFrom(data: configData).json
            {
                Optimove.sharedInstance.logger.severe("Try to configure from disk")
                if OptimoveComponentsInitializer.atomicBool.compareAndSet(expected: false, value: true) {
                    self.setupOptimoveComponents(from: json)
                }
                else {
                    Optimove.sharedInstance.logger.debug("skipping local initialization since already initialized")
                }
            }
        }
    }
    
    //MARK: - Internal Methods
    fileprivate func setupOptimoveComponents(from json: [String:Any])
    {
        guard !Optimove.sharedInstance.monitor.isSdkInitialized()
        else
        {
            Optimove.sharedInstance.logger.debug("SDK already initialize, skip initializeation")
            return
        }
        Optimove.sharedInstance.monitor.setup(from: json)
        Optimove.sharedInstance.eventValidator = EventValidator(from: json)
        if Optimove.sharedInstance.eventValidator != nil
        {
            Optimove.sharedInstance.monitor.update(component: .validator, state: .active)
        }
        else
        {
            Optimove.sharedInstance.monitor.update(component: .validator, state: .inactive)
        }
        
        Optimove.sharedInstance.optiTrack = OptiTrack(from: json,initializationDelegate: self)
        if Optimove.sharedInstance.optiTrack != nil
        {
            self.didFinishInitialization(of: .optiTrack)
        }
        
        Optimove.sharedInstance.optiPush = Optipush(from: json,
                                                    clientHasFirebase: self.clientHasFirebase,
                                                    initializationDelegate: self)
        if Optimove.sharedInstance.optiPush != nil
        {
            self.didFinishInitialization(of: .optiPush)
        }
        
    }
    
    
    
    //MARK: - Private Methods
    
    private func saveConfigurationToFile(data:Data)
    {
        Optimove.sharedInstance.logger.debug("Storing configuration in disk")
        let actionFile = "configuration_data.json"
        do
        {
            try FileManager.default.createDirectory(at: OptimoveFileManager.shared.optimoveSDKDirectory, withIntermediateDirectories: true)
            let fileURL = OptimoveFileManager.shared.optimoveSDKDirectory.appendingPathComponent(actionFile)
            let success = FileManager.default.createFile(atPath: fileURL.path, contents: data, attributes: nil)
            
            Optimove.sharedInstance.logger.debug("Storing status is \(success.description)\n location:\(OptimoveFileManager.shared.optimoveSDKDirectory.path)")
        }
        catch
        {
//            Optimove.sharedInstance.logger.severe("\(OptimoveError.cantStoreFileInLocalStorage.localizedDescription)")
            
            return
        }
    }
    fileprivate func finishSdkInit(with errors: [OptimoveError]? = nil)
    {
        Optimove.sharedInstance.monitor.updateSDKState(with: errors)
    }
}

extension OptimoveComponentsInitializer : ComponentInitializationDelegate
{
    func didFinishInitialization(of component:Component)
    {
        var state = Optimove.sharedInstance.monitor.getState(of: component) ?? State.Component.inactive
        switch state {
        case .permitted:
            state = .active
        case .denied:
            state = .activeInternal
        default:
            state = .inactive
        }
        Optimove.sharedInstance.monitor.update(component: component, state: state)
        notifyCompponentFinish()
    }
    func didFailInitialization(of component:Component,rootCause:OptimoveError)
    {
        initializationErrors.append(rootCause)
        Optimove.sharedInstance.monitor.update(component: component, state: .inactive)
        notifyCompponentFinish()
    }
    
    fileprivate func notifyCompponentFinish()
    {
        numOfInitializedObjects += 1
        if numOfInitializedObjects == 2
        {
            self.finishSdkInit(with: self.initializationErrors)
        }
    }
}




