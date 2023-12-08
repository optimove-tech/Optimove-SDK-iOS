//  Copyright © 2020 Optimove. All rights reserved.

import Foundation
import OptimoveCore

protocol MigrationWork {
    func isAllowToMiragte(_ currentVersion: String) -> Bool
    func runMigration()
}

private protocol Replacer {
    func replace()
}

class MigrationWorker: MigrationWork {
    let version: Version

    init(
        newVersion: Version
    ) {
        version = newVersion
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
        guard !storage.isAlreadyMigrated(to: version.rawValue) else {
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
    private let synchronizer: Pipeline

    init(
        synchronizer: Pipeline,
        storage: OptimoveStorage
    ) {
        self.synchronizer = synchronizer
        super.init(storage: storage, newVersion: .v_2_10_0)
    }

    override func runMigration() {
        synchronizer.deliver(.setInstallation)
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

    override func isAllowToMiragte(_: String) -> Bool {
        guard let storage = try? UserDefaults.optimove() else {
            return true
        }
        let key = StorageKey.migrationVersions
        let versions = storage.object(forKey: key.rawValue) as? [String] ?? []
        return !versions.contains(version.rawValue)
    }

    override func runMigration() {
        let replacers: [Replacer] = [
            UserDefaultsReplacer(),
            AppGroupReplacer(),
        ]
        replacers.forEach { $0.replace() }
        super.runMigration()
    }
}

extension MigrationWork_3_3_0 {
    final class AppGroupReplacer: Replacer {
        func replace() {
            do {
                try moveDefautlsFromAppGroup()
                try moveFilesFromAppGroup()
                try markMigrationAsCompleted()
            } catch {
                try? markMigrationAsCompleted()
                Logger.error(error.localizedDescription)
            }
        }

        func moveDefautlsFromAppGroup() throws {
            let bundleID = try Bundle.getApplicationNameSpace()
            let oldDefaults = try getDeprecatedUserDefaultsGrouped(tenantBundleIdentifier: bundleID)
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
                .migrationVersions,
                .firstRunTimestamp,
            ]
            groupKeys.forEach { key in
                if let value = oldDefaults.value(for: key) {
                    newDefaults.set(value: value, key: key)
                    oldDefaults.removeObject(forKey: key.rawValue)
                }
            }
        }

        func moveFilesFromAppGroup() throws {
            let bundleID = try Bundle.getApplicationNameSpace()
            let oldURL = try getDeprecatedFileManagerGroupContainerURL(tenantBundleIdentifier: bundleID).appendingPathComponent("OptimoveSDK")
            let newURL = try FileManager.optimoveURL()
            let fileManager = FileManager.default
            var isDirectory: ObjCBool = false
            let exists = FileManager.default.fileExists(atPath: oldURL.absoluteString, isDirectory: &isDirectory)
            guard exists, isDirectory.boolValue else {
                return
            }
            let files = try FileManager.default.contentsOfDirectory(atPath: oldURL.absoluteString)
            try files.forEach { file in
                let oldPath = oldURL.appendingPathComponent(file)
                try fileManager.moveItem(at: oldPath, to: newURL.appendingPathComponent(file))
                try fileManager.removeItem(at: oldPath)
            }
        }

        func markMigrationAsCompleted() throws {
            let newDefaults = try UserDefaults.optimove()
            let key = StorageKey.migrationVersions
            var versions = newDefaults.object(forKey: key.rawValue) as? [String] ?? []
            versions.append(Version.v_3_3_0.rawValue)
            newDefaults.set(value: versions, key: key)
        }

        private func getDeprecatedUserDefaultsGrouped(tenantBundleIdentifier: String) throws -> UserDefaults {
            let suiteName = "group.\(tenantBundleIdentifier).optimove"
            guard let userDefaults = UserDefaults(suiteName: suiteName) else {
                throw GuardError.custom(
                    """
                    Unable to initialize UserDefault with suit name "\(suiteName)".
                    Highly possible that the client forgot to add the app group as described in the documentation.
                    """
                )
            }
            return userDefaults
        }

        private func getDeprecatedFileManagerGroupContainerURL(tenantBundleIdentifier: String) throws -> URL {
            let groupIdentifier = "group.\(tenantBundleIdentifier).optimove"
            guard let url = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: groupIdentifier) else {
                throw GuardError.custom(
                    """
                    Unable to initialize FileManager container for the application group identifier "\(groupIdentifier)".
                    Highly possible that the client forgot to add the app group as described in the documentation.
                    """
                )
            }
            return url
        }
    }

    final class UserDefaultsReplacer: Replacer {
        func replace() {
            do {
                let oldDefaults = UserDefaults.standard
                let newDefaults = try UserDefaults.optimove()
                let sharedKeys: Set<StorageKey> = [
                    .userEmail,
                    .siteID,
                    .settingUserSuccess,
                    .firstVisitTimestamp,
                ]
                sharedKeys.forEach { key in
                    let value = oldDefaults.value(for: key)
                    newDefaults.set(value: value, key: key)
                    oldDefaults.removeObject(forKey: key.rawValue)
                }
            } catch {
                Logger.error(error.localizedDescription)
            }
        }
    }
}

/// Migration from Kumulos UserDefaults to Optimove UserDefaults.
final class MigrationWork_5_7_0: MigrationWorker {
    init() {
        super.init(newVersion: .v_5_7_0)
    }

    override func isAllowToMiragte(_: String) -> Bool {
        guard let storage = try? UserDefaults.optimove() else {
            return true
        }
        let key = StorageKey.migrationVersions
        let versions = storage.object(forKey: key.rawValue) as? [String] ?? []
        return !versions.contains(version.rawValue)
    }

    override func runMigration() {
        Logger.info("Migration from Kumulos UserDefaults to Optimove UserDefaults started")
        let keyMapping: [DeprecatedOptimobileKey: StorageKey] = [
            .REGION: .region,
            .MEDIA_BASE_URL: .mediaURL,
            .INSTALL_UUID: .installUUID,
            .USER_ID: .userID,
            .BADGE_COUNT: .badgeCount,
            .PENDING_NOTIFICATIONS: .pendingNotifications,
            .PENDING_ANALYTICS: .pendingAnaltics,
            .IN_APP_LAST_SYNCED_AT: .inAppLastSyncedAt,
            .IN_APP_MOST_RECENT_UPDATED_AT: .inAppMostRecentUpdateAt,
            .IN_APP_CONSENTED: .inAppConsented,
            .DYNAMIC_CATEGORY: .dynamicCategory,
            .KUMULOS_DDL_CHECKED: .deferredLinkChecked,
        ]
        /// Move values from Kumulos UserDefaults to Optimove UserDefaults.
        let kumulosStandardStorage = UserDefaults.standard
        let optimoveStandardStorage = try! UserDefaults.optimove()
        let optimoveAppGroupStorage = try! UserDefaults.optimoveAppGroup()
        DeprecatedOptimobileKey.allCases.forEach { key in
            if let value = kumulosStandardStorage.object(forKey: key.rawValue),
               let storageKey = keyMapping[key]
            {
                optimoveStandardStorage.set(value: value, key: storageKey)
                kumulosStandardStorage.removeObject(forKey: key.rawValue)
            }
        }
        /// Rename Kumulos keys to Optimove keys.
        DeprecatedOptimobileKey.allCases.forEach { key in
            if let value = optimoveStandardStorage.object(forKey: key.rawValue),
               let storageKey = keyMapping[key]
            {
                optimoveStandardStorage.removeObject(forKey: key.rawValue)
                optimoveStandardStorage.set(value: value, key: storageKey)
            }
            if let value = optimoveAppGroupStorage.object(forKey: key.rawValue),
               let storageKey = keyMapping[key]
            {
                optimoveAppGroupStorage.removeObject(forKey: key.rawValue)
                optimoveAppGroupStorage.set(value: value, key: storageKey)
            }
        }
        /// Remove Kumulos UserDefaults keys.
        ["KumulosDidMigrateToAppGroups"].forEach { key in
            kumulosStandardStorage.removeObject(forKey: key)
            optimoveAppGroupStorage.removeObject(forKey: key)
        }
        Logger.info("Migration from Kumulos UserDefaults to Optimove UserDefaults completed")
        super.runMigration()
    }
}
