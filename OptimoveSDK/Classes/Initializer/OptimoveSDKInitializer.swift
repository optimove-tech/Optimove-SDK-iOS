//
//  Initializer.swift
//  OptimoveSDKDev
//
//  Created by Mobile Developer Optimove on 13/09/2017.
//  Copyright © 2017 Optimove. All rights reserved.
//

import Foundation

final class OptimoveSDKInitializer {

    // MARK: - Private Variables

    private static let semaphore = DispatchSemaphore(value: 1)

    private let configuratorFactory: ComponentConfiguratorFactory
    private let warehouseProvider: EventsConfigWarehouseProvider
    private let deviceStateMonitor: OptimoveDeviceStateMonitor
    private let storage: OptimoveStorage
    private let networking: RemoteConfigurationNetworking

    private var requirementStateDictionary: [OptimoveDeviceRequirement: Bool]
    private var completionHandler: ResultBlockWithBool?
    private var didSucceed: ResultBlockWithBool?
    private var componentsCounter = 0

    // MARK: - Initializers

    init(deviceStateMonitor: OptimoveDeviceStateMonitor,
         configuratorFactory: ComponentConfiguratorFactory,
         warehouseProvider: EventsConfigWarehouseProvider,
         storage: OptimoveStorage,
         networking: RemoteConfigurationNetworking) {
        OptiLoggerMessages.logInitializtionOfInsitalizerStart()
        self.deviceStateMonitor = deviceStateMonitor
        self.configuratorFactory = configuratorFactory
        self.warehouseProvider = warehouseProvider
        self.storage = storage
        self.networking = networking
        requirementStateDictionary = [:]
        OptiLoggerMessages.logInitializerInitializtionFinish()
    }

    // MARK: - Internal API

    func initializeFromRemoteServer(didComplete: @escaping ResultBlockWithBool) {
        self.didSucceed = didComplete

        deviceStateMonitor.getStatus(for: .internet) { (available) in
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
        networking.downloadConfigurations { (result) in
            switch result {
            case let .success(configurations):
                self.updateEnvironment(configurations)
                OptiLoggerMessages.logSetupComponentsFromRemote()
                guard RunningFlagsIndication.isSdkNeedInitializing() else { return }
                self.setupOptimoveComponents(from: configurations)
            case let .failure(error):
                OptiLoggerMessages.logError(error: error)
                self.didSucceed?(false)
            }
        }
    }

    private func updateEnvironment(_ config: TenantConfig) {
        saveConfigurationToLocalStorage(config)
        updateLoggerStreamContainers(config)
        setupStorage(from: config)
    }
    
    private func updateLoggerStreamContainers(_ config: TenantConfig) {
        guard let newTenantId = config.optitrackMetaData?.siteId else { return }
        OptiLoggerStreamsContainer.outputStreams.values
            .compactMap { $0 as? MutableOptiLoggerOutputStream }
            .forEach { $0.tenantId = newTenantId }
    }

    private func handleFetchConfigurationFromLocal() {
        let isExist: Bool = {
            if let version = storage.version, let isExist = try? storage.isExist(fileName: version + ".json", shared: true) {
                return isExist
            }
            return false
        }()
        guard isExist else {
            OptiLoggerMessages.logConfigFileNotExist()
            //TODO: delete all configuration files because they are not relevant to current version anymore
            return
        }
        LocalConfigurationHandler(storage: storage).get { (configurationData, error) in
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
                self.setupStorage(from: parsed)
                self.setupOptimoveComponents(from: parsed)
            } catch {
                OptiLoggerMessages.logConfigurationParsingError()
            }
        }
    }

    private func saveConfigurationToLocalStorage(_ configuration: TenantConfig) {
        guard let version = storage.version else { return }
        let fileName = version + ".json"
        do {
            try storage.save(
                data: configuration,
                toFileName: fileName,
                shared: true
            )
        } catch {
            OptiLoggerMessages.logError(error: error)
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

    private func setupStorage(from tenantConfig: TenantConfig) {
        if let siteId = tenantConfig.optitrackMetaData?.siteId {
            storage.set(value: siteId, key: .siteID)
        }
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
        warehouseProvider.setWarehouse(OptimoveEventConfigsWarehouseImpl(from: tenantConfig))
        group.enter()
        configuratorFactory.createOptiTrackConfigurator().configure(from: tenantConfig) { (succeed) in
            RunningFlagsIndication.setComponentRunningFlag(component: .optiTrack, state: succeed)
            group.leave()
        }
        group.enter()
        configuratorFactory.createOptiPushConfigurator().configure(from: tenantConfig) { (succeed) in
            RunningFlagsIndication.setComponentRunningFlag(component: .optiPush, state: succeed)
            group.leave()
        }
        group.enter()
        configuratorFactory.createRealTimeConfigurator().configure(from: tenantConfig) { (succeed) in
            RunningFlagsIndication.setComponentRunningFlag(component: .realtime, state: succeed)
            group.leave()
        }
        group.notify(queue: .main) {
            self.handleEndOfComponentInitialization()
        }
    }
}
