//  Copyright © 2019 Optimove. All rights reserved.

import Foundation

public protocol ConfigurationRepository {

    func getConfiguration() throws -> Configuration
    func setConfiguration(_: Configuration) throws

    func getGlobal() throws -> GlobalConfig
    func saveGlobal(_: GlobalConfig) throws

    func getTenant() throws -> TenantConfig
    func saveTenant(_: TenantConfig) throws

}

public final class ConfigurationRepositoryImpl {

    private struct Constants {
        static let fileExtension = ".json"
        struct Global {
            static let fileName = "global_config" + fileExtension
            static let isGroupContainer = true
        }
        struct Tenant {
            static let isGroupContainer = true
        }
        struct Configuration {
            static let fileName = "configuration" + fileExtension
            static let isGroupContainer = true
        }
    }

    private let storage: OptimoveStorage

    public init(storage: OptimoveStorage) {
        self.storage = storage
    }

}

extension ConfigurationRepositoryImpl: ConfigurationRepository {

    public func getConfiguration() throws -> Configuration {
        return try storage.load(fileName: Constants.Configuration.fileName,
                                isGroupContainer: Constants.Configuration.isGroupContainer)
    }

    public func setConfiguration(_ config: Configuration) throws {
        try storage.save(data: config,
                         toFileName: Constants.Configuration.fileName,
                         isGroupContainer: Constants.Configuration.isGroupContainer)
    }

    public func getGlobal() throws -> GlobalConfig {
        return try storage.load(fileName: Constants.Global.fileName,
                                isGroupContainer: Constants.Global.isGroupContainer)
    }

    public func saveGlobal(_ config: GlobalConfig) throws {
        try storage.save(data: config,
                         toFileName: Constants.Global.fileName,
                         isGroupContainer: Constants.Global.isGroupContainer)
    }

    public func getTenant() throws -> TenantConfig {
        let version = try storage.getVersion()
        let fileName = version + Constants.fileExtension
        return try storage.load(fileName: fileName,
                                isGroupContainer: Constants.Tenant.isGroupContainer)
    }

    public func saveTenant(_ config: TenantConfig) throws {
        let version = try storage.getVersion()
        let fileName = version + Constants.fileExtension
        try storage.save(data: config,
                         toFileName: fileName,
                         isGroupContainer: Constants.Tenant.isGroupContainer)
    }
}
