//
//  Initializer.swift
//  OptimoveSDKDev
//
//  Created by Mobile Developer Optimove on 13/09/2017.
//  Copyright © 2017 Optimove. All rights reserved.
//

import Foundation

class OptimoveSDKInitializer
{
    //MARK: - Private Variables
    
    private var requirementStateDictionary: [OptimoveDeviceRequirement:Bool]
    private var completionHandler:ResultBlockWithBool?
    
    private var componentsCounter = 0
    static let semaphore = DispatchSemaphore(value: 1)
    
    var didSucceed: ResultBlockWithBool?
    
    //MARK: - Constants
    
    let deviceStateMonitor:OptimoveDeviceStateMonitor
    
    //MARK: - Initializers
    init(deviceStateMonitor:OptimoveDeviceStateMonitor )
    {
        OptiLogger.debug("Initialize OptimoveComponentInitializer")
        self.deviceStateMonitor = deviceStateMonitor
        requirementStateDictionary = [:]
        OptiLogger.debug("Finish OptimoveComponentInitializer initialization")
    }
    //MARK: - Internal API
    func initializeFromRemoteServer(didComplete: @escaping ResultBlockWithBool)
    {
        self.didSucceed = didComplete
        
        deviceStateMonitor.getStatus(of: .internet) { (available) in
            if available {
                self.handleFetchConfigurationFromRemote()
            } else {
                didComplete(false)
            }
        }
    }
    
    ///When the SDK is initialized by a push notification start the initialization from the local JSON file
    func initializeFromLocalConfigs(didSucceed: @escaping ResultBlockWithBool)
    {
        OptiLogger.debug("start initializtion from local configurations")
        self.didSucceed = didSucceed
        handleFetchConfigurationFromLocal()
    }
    
    //MARK: - Private methods
    
    private func handleFetchConfigurationFromRemote()
    {
        RemoteConfigurationHandler().get { (configurationData, error) in
            guard error == nil else {
                self.didSucceed!(false)
                return
            }
            guard let data = configurationData else {
                self.didSucceed?(false)
                return
            }
            let decoder = JSONDecoder()
            do {
                let parsed = try decoder.decode(TenantConfig.self, from: data)
                self.saveConfigurationToLocalStorage(data)
                OptiLogger.debug("setup components from remote")
                guard RunningFlagsIndication.isSdkNeedInitializing() else {return}
                self.setupOptimoveComponents(from: parsed)
            } catch {
                self.didSucceed?(false)
            }
        }
    }

    private func handleFetchConfigurationFromLocal()
    {
        guard let version = Version,
            OptimoveFileManager.isExist(file: version+".json") else {
                OptiLogger.debug("configurtion file not exist")
                //TODO: delete all configuration files because they are not relevant to current version anymore
                return
        }
        LocalConfigurationHandler().get { (configurationData, error) in
            guard error == nil else {
                OptiLogger.error("error when fetching configurstion file from local storage")
                return
            }
            OptiLogger.debug("Got configuration file from local storage ")
            guard let data = configurationData else {
                    OptiLogger.error("configuration data corrupt")
                    return
            }
            
            let decoder = JSONDecoder()
            do {
            let parsed = try decoder.decode(TenantConfig.self, from: data)
            
                OptiLogger.debug("setup components from local")
            self.setupOptimoveComponents(from: parsed )
            }
            catch {
                OptiLogger.error("local configuration could not be parsed")
            }
        }
    }
    
    private func saveConfigurationToLocalStorage(_ data:Data)
    {
        if let version = OptimoveUserDefaults.shared.version {
            let fileName = version + ".json"
            OptimoveFileManager.save(data: data, toFileName: fileName)
        }
    }
    
    private func handleEndOfComponentInitialization()
    {
        OptiLogger.debug("All components setup finished")
        let success = didFinishSdkInitializtionSucceesfully()
        if success {
            Optimove.sharedInstance.didFinishInitializationSuccessfully()
        }
        self.didSucceed!(success)
    }
    
    func didFinishSdkInitializtionSucceesfully()-> Bool
    {
        for (_,running) in RunningFlagsIndication.componentsRunningStates {
            if running {
                return true
            }
        }
        return false
    }
    
    private func setupOptimoveComponents(from tenantConfig: TenantConfig)
    {
        guard RunningFlagsIndication.isSdkNeedInitializing() else
        {
            OptiLogger.debug("SDK already running, skip initialization before lock")
            return
        }
        OptimoveSDKInitializer.semaphore.wait()
        guard RunningFlagsIndication.isSdkNeedInitializing() else
        {
            OptiLogger.debug("SDK already running, skip initialization inside lock")
            return
        }
        RunningFlagsIndication.isInitializerRunning = true
        OptimoveSDKInitializer.semaphore.signal()
        
        let group = DispatchGroup()
        Optimove.sharedInstance.eventWarehouse = OptimoveEventConfigsWarehouse(from: tenantConfig)
        group.enter()
        OptiTrackConfigurator(component: Optimove.sharedInstance.optiTrack).configure(from: tenantConfig) { (succeed) in
            RunningFlagsIndication.setComponentRunningFlag(component: .optiTrack, state: succeed)
            group.leave()
        }
        group.enter()
        OptiPushConfigurator(component: Optimove.sharedInstance.optiPush).configure(from: tenantConfig) { (succeed) in
            RunningFlagsIndication.setComponentRunningFlag(component: .optiPush, state: succeed)
            group.leave()
        }
        group.enter()
        RealTimeConfigurator(component: Optimove.sharedInstance.realTime).configure(from: tenantConfig) { (succeed) in
            RunningFlagsIndication.setComponentRunningFlag(component: .realtime, state: succeed)
            group.leave()
        }
        group.notify(queue: .main) {
            self.handleEndOfComponentInitialization()
        }
    }
}
