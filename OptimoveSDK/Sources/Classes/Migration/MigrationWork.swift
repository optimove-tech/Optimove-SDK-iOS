//  Copyright © 2020 Optimove. All rights reserved.

import OptimoveCore

protocol MigrationWork {
    func isAllowToMiragte(_ currentVersion: String) -> Bool
    func runMigration()
}

class MigrationWorker: MigrationWork {

    let version: Version

    init(
        newVersion: Version
    ) {
        self.version = newVersion
    }

    func isAllowToMiragte(_ currentVersion: String) -> Bool {
        switch version.rawValue.compare(currentVersion, options: .numeric) {
        case .orderedSame, .orderedAscending:
            return true
        default:
            return false
        }
    }

    /// Have to call `super.runMigration()` in case of overrideding.
    func runMigration() {}
}

class MigrationWorkerWithStorage: MigrationWorker {

    fileprivate var storage: OptimoveStorage

    init(
        storage: OptimoveStorage,
        newVersion: Version
    ) {
        self.storage = storage
        super.init(newVersion: newVersion)
    }

    override func isAllowToMiragte(_ currentVersion: String) -> Bool {
        guard !storage.isAlreadyMigrated(to: currentVersion) else {
            return false
        }
        return super.isAllowToMiragte(currentVersion)
    }

    override func runMigration() {
        storage.finishedMigration(to: version.rawValue)
        super.runMigration()
    }

}

final class MigrationWork_2_10_0: MigrationWorkerWithStorage {

    private let synchronizer: Synchronizer

    init(synchronizer: Synchronizer,
         storage: OptimoveStorage) {
        self.synchronizer = synchronizer
        super.init(storage: storage, newVersion: .v_2_10_0)
    }

    override func runMigration() {
        synchronizer.handle(.setInstallation)
        super.runMigration()
    }

}

final class MigrationWork_3_0_0: MigrationWorkerWithStorage {

    init(storage: OptimoveStorage) {
        super.init(storage: storage, newVersion: .v_3_0_0)
    }

    override func runMigration() {
        if storage.firstRunTimestamp == nil {
            storage.firstRunTimestamp = storage.firstVisitTimestamp
        }
        super.runMigration()
    }

}

/// Migation from AppGroup to the main container.
final class MigrationWork_3_3_0: MigrationWorker {

    init() {
        super.init(newVersion: .v_3_3_0)
    }

    override func runMigration() {
        let replacers: [Replacer] = [
            UserDefaultsReplacer(),
            AppGroupReplacer()
        ]
        replacers.forEach { $0.replace() }
        super.runMigration()
    }

}

private protocol Replacer {
    func replace()
}

extension MigrationWork_3_3_0 {

    final class AppGroupReplacer: Replacer {
        func replace() {
            do {
                try moveDefautlsFromAppGroup()
                try moveFilesFromAppGroup()
                try markMigrationAsCompleted()
            } catch {
                Logger.error(error.localizedDescription)
            }
        }

        func moveDefautlsFromAppGroup() throws {
            let bundleID =  try Bundle.getApplicationNameSpace()
            let oldDefaults = try UserDefaults.grouped(tenantBundleIdentifier: bundleID)
            let newDefaults = try UserDefaults.optimove()
            newDefaults.setValuesForKeys(oldDefaults.dictionaryRepresentation())
        }

        func moveFilesFromAppGroup() throws {
            let bundleID =  try Bundle.getApplicationNameSpace()
            let oldURL = try FileManager.default.groupContainer(tenantBundleIdentifier: bundleID).appendingPathComponent("OptimoveSDK")
            let newURL = try FileManager.optimoveURL()
            let fileManager = FileManager.default
            let files = try FileManager.default.contentsOfDirectory(atPath: oldURL.absoluteString)
            try files.forEach({ file in
                let oldPath = oldURL.appendingPathComponent(file)
                try fileManager.moveItem(at: oldPath, to: newURL.appendingPathComponent(file))
                try fileManager.removeItem(at: oldPath)
            })
        }

        func markMigrationAsCompleted() throws {
            let newDefaults = try UserDefaults.optimove()
            let key = StorageKey.migrationVersions
            guard var versions = newDefaults.object(forKey: key.rawValue) as? [String] else {
                return
            }
            versions.append(Version.v_3_3_0.rawValue)
            newDefaults.set(value: versions, key: key)
        }
    }

    final class UserDefaultsReplacer: Replacer {
        func replace() {
            do {
                let oldDefaults = UserDefaults.shared()
                let newDefaults = try UserDefaults.optimove()
                let groupKeys: Set<StorageKey> = [
                    .optitrackEndpoint,
                    .tenantID,
                    .installationID,
                    .customerID,
                    .configurationEndPoint,
                    .initialVisitorId,
                    .tenantToken,
                    .visitorID,
                    .version,
                    .userAgent,
                    .deviceResolutionWidth,
                    .deviceResolutionHeight,
                    .advertisingIdentifier,
                    .optFlag,
                    .migrationVersions,
                    .arePushCampaignsDisabled,
                    .firstRunTimestamp
                ]
                groupKeys.forEach({ key in
                    let value = oldDefaults.value(for: key)
                    newDefaults.set(value: value, key: key)
                    oldDefaults.removeObject(forKey: key.rawValue)
                })
            } catch {
                Logger.error(error.localizedDescription)
            }
        }
    }

}
