//
//  Initializer.swift
//  OptimoveSDKDev
//
//  Created by Mobile Developer Optimove on 13/09/2017.
//  Copyright © 2017 Optimove. All rights reserved.
//

import Foundation

class OptimoveSDKInitializer {
    // MARK: - Private Variables

    private var requirementStateDictionary: [OptimoveDeviceRequirement: Bool]
    private var completionHandler: ResultBlockWithBool?

    private var componentsCounter = 0
    static let semaphore = DispatchSemaphore(value: 1)

    var didSucceed: ResultBlockWithBool?

    // MARK: - Constants

    let deviceStateMonitor: OptimoveDeviceStateMonitor

    // MARK: - Initializers
    init(deviceStateMonitor: OptimoveDeviceStateMonitor ) {
        OptiLoggerMessages.logInitializtionOfInsitalizerStart()
        self.deviceStateMonitor = deviceStateMonitor
        requirementStateDictionary = [:]
        OptiLoggerMessages.logInitializerInitializtionFinish()
    }
    // MARK: - Internal API
    func initializeFromRemoteServer(didComplete: @escaping ResultBlockWithBool) {
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
    func initializeFromLocalConfigs(didSucceed: @escaping ResultBlockWithBool) {
        OptiLoggerMessages.logStartOfLocalInitializtion()
        self.didSucceed = didSucceed
        handleFetchConfigurationFromLocal()
    }

    // MARK: - Private methods

    private func handleFetchConfigurationFromRemote() {
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

                if let tid = TenantID {
                    for stream in OptiLoggerStreamsContainer.outputStreams.values {
                        guard let serviceStream = stream as? MobileLogServiceLoggerStream else { continue }
                        serviceStream.tenantId = tid
                        break
                    }
                }

                self.saveConfigurationToLocalStorage(data)
                OptiLoggerMessages.logSetupComponentsFromRemote()
                guard RunningFlagsIndication.isSdkNeedInitializing() else {return}
                self.setupOptimoveComponents(from: parsed)
            } catch {
                self.didSucceed?(false)
            }
        }
    }

    private func handleFetchConfigurationFromLocal() {
        guard let version = Version,
            OptimoveFileManager.isExist(file: version+".json", isInSharedContainer: true) else {
                OptiLoggerMessages.logConfigFileNotExist()
                //TODO: delete all configuration files because they are not relevant to current version anymore
                return
        }
        LocalConfigurationHandler().get { (configurationData, error) in
            guard error == nil else {
                OptiLoggerMessages.logLocalFetchFailure()
                return
            }
            OptiLoggerMessages.logLocalConfigFileFetchSuccess()
            guard let data = configurationData else {
                    OptiLoggerMessages.logIssueWithConfigFile()
                    return
            }

            let decoder = JSONDecoder()
            do {
            let parsed = try decoder.decode(TenantConfig.self, from: data)

                OptiLoggerMessages.logSetupCopmponentsFromLocalConfiguraitonStart()
            self.setupOptimoveComponents(from: parsed )
            } catch {
                OptiLoggerMessages.logConfigurationParsingError()
            }
        }
    }

    private func saveConfigurationToLocalStorage(_ data: Data) {
        if let version = OptimoveUserDefaults.shared.version {
            let fileName = version + ".json"
            OptimoveFileManager.save(data: data, toFileName: fileName, isForSharedContainer: true)
        }
    }

    private func handleEndOfComponentInitialization() {
        OptiLoggerMessages.logSuccessfulyFinishOfComponentsSetup()
        let success = didFinishSdkInitializtionSucceesfully()
        if success {
            Optimove.shared.didFinishInitializationSuccessfully()
        }
        self.didSucceed!(success)
    }

    func didFinishSdkInitializtionSucceesfully() -> Bool {
        for (_, running) in RunningFlagsIndication.componentsRunningStates {
            if running {
                return true
            }
        }
        return false
    }

    private func setupOptimoveComponents(from tenantConfig: TenantConfig) {
        guard RunningFlagsIndication.isSdkNeedInitializing() else {
            OptiLoggerMessages.logSdkAlreadyRunning()
            return
        }
        OptimoveSDKInitializer.semaphore.wait()
        guard RunningFlagsIndication.isSdkNeedInitializing() else {
            OptiLoggerMessages.logSdkAlreadyRunning()
            return
        }
        RunningFlagsIndication.isInitializerRunning = true
        OptimoveSDKInitializer.semaphore.signal()

        let group = DispatchGroup()
        Optimove.shared.eventWarehouse = OptimoveEventConfigsWarehouse(from: tenantConfig)
        group.enter()
        OptiTrackConfigurator(component: Optimove.shared.optiTrack).configure(from: tenantConfig) { (succeed) in
            RunningFlagsIndication.setComponentRunningFlag(component: .optiTrack, state: succeed)
            group.leave()
        }
        group.enter()
        OptiPushConfigurator(component: Optimove.shared.optiPush).configure(from: tenantConfig) { (succeed) in
            RunningFlagsIndication.setComponentRunningFlag(component: .optiPush, state: succeed)
            group.leave()
        }
        group.enter()
        RealTimeConfigurator(component: Optimove.shared.realTime).configure(from: tenantConfig) { (succeed) in
            RunningFlagsIndication.setComponentRunningFlag(component: .realtime, state: succeed)
            group.leave()
        }
        group.notify(queue: .main) {
            self.handleEndOfComponentInitialization()
        }
    }
}
