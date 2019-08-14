//  Copyright © 2019 Optimove. All rights reserved.

import Foundation

public protocol ConfigurationRepository {

    func getConfiguration() throws -> Configuration
    func setConfiguration(_: Configuration) throws

    func getGlobal() throws -> GlobalConfig
    func saveGlobal(_: GlobalConfig) throws

    func saveTenant(_: TenantConfig) throws
    func getTenant() throws -> TenantConfig

}

public final class ConfigurationRepositoryImpl {

    private struct Constants {
        static let fileExtension = ".json"
        struct Global {
            static let fileName = "global_config" + fileExtension
            static let sharedStorage = true
        }
        struct Tenant {
            static let sharedStorage = true
        }
        struct Configuration {
            static let fileName = "configuration" + fileExtension
            static let sharedStorage = true
        }
    }

    private let storage: OptimoveStorage

    public init(storage: OptimoveStorage) {
        self.storage = storage
    }

}

extension ConfigurationRepositoryImpl: ConfigurationRepository {

    public func getConfiguration() throws -> Configuration {
        let data = try storage.load(fileName: Constants.Configuration.fileName, shared: Constants.Configuration.sharedStorage)
        return try JSONDecoder().decode(Configuration.self, from: data)
    }

    public func setConfiguration(_ config: Configuration) throws {
        try storage.save(data: config,
                         toFileName: Constants.Configuration.fileName, shared: Constants.Configuration.sharedStorage)
    }

    public func getGlobal() throws -> GlobalConfig {
        let data = try storage.load(fileName: Constants.Global.fileName, shared: Constants.Global.sharedStorage)
        return try JSONDecoder().decode(GlobalConfig.self, from: data)
    }

    public func saveGlobal(_ config: GlobalConfig) throws {
        try storage.save(data: config, toFileName: Constants.Global.fileName, shared: Constants.Global.sharedStorage)
    }

    public func getTenant() throws -> TenantConfig {
        let version = try storage.getVersion()
        let fileName = version + Constants.fileExtension
        let data = try storage.load(fileName: fileName, shared: Constants.Tenant.sharedStorage)
        return try JSONDecoder().decode(TenantConfig.self, from: data)
    }

    public func saveTenant(_ config: TenantConfig) throws {
        let version = try storage.getVersion()
        let fileName = version + Constants.fileExtension
        try storage.save(data: config, toFileName: fileName, shared: Constants.Tenant.sharedStorage)
    }
}

