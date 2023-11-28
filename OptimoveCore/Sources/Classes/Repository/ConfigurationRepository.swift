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
    private enum Constants {
        static let fileExtension = ".json"
        enum Global {
            static let fileName = "global_config" + fileExtension
            static let isGroupContainer = true
        }

        enum Tenant {
            static let isGroupContainer = true
        }

        enum Configuration {
            static let fileName = "configuration" + fileExtension
        }
    }

    private let storage: OptimoveStorage

    public init(storage: OptimoveStorage) {
        self.storage = storage
    }
}

extension ConfigurationRepositoryImpl: ConfigurationRepository {
    public func getConfiguration() throws -> Configuration {
        return try storage.load(fileName: Constants.Configuration.fileName, isTemporary: true)
    }

    public func setConfiguration(_ config: Configuration) throws {
        try storage.save(data: config, toFileName: Constants.Configuration.fileName, isTemporary: true)
    }

    public func getGlobal() throws -> GlobalConfig {
        return try storage.load(fileName: Constants.Global.fileName)
    }

    public func saveGlobal(_ config: GlobalConfig) throws {
        try storage.save(data: config, toFileName: Constants.Global.fileName)
    }

    public func getTenant() throws -> TenantConfig {
        let version = try storage.getVersion()
        let fileName = version + Constants.fileExtension
        return try storage.load(fileName: fileName, isTemporary: true)
    }

    public func saveTenant(_ config: TenantConfig) throws {
        let version = try storage.getVersion()
        let fileName = version + Constants.fileExtension
        try storage.save(data: config, toFileName: fileName, isTemporary: true)
    }
}
