//  Copyright © 2022 Optimove. All rights reserved.

import Foundation

protocol KeyValPersistent {
    static func set(_ value: Any?, forKey: String)
    static func object(forKey: String) -> Any?
    static func removeObject(forKey: String)
}

enum KeyValPersistenceHelper {
    static func maybeMigrateUserDefaultsToAppGroups() {
        let standardDefaults = UserDefaults.standard
        let haveMigratedKey: String = OptimobileUserDefaultsKey.MIGRATED_TO_GROUPS.rawValue
        if !AppGroupsHelper.isKumulosAppGroupDefined() {
            standardDefaults.set(false, forKey: haveMigratedKey)
            return
        }

        guard let groupDefaults = UserDefaults(suiteName: AppGroupsHelper.getKumulosGroupName()) else { return }
        if groupDefaults.bool(forKey: haveMigratedKey), standardDefaults.bool(forKey: haveMigratedKey) {
            return
        }

        let defaultsAsDict: [String: Any] = standardDefaults.dictionaryRepresentation()
        for key in OptimobileUserDefaultsKey.sharedKeys {
            groupDefaults.set(defaultsAsDict[key.rawValue], forKey: key.rawValue)
        }

        standardDefaults.set(true, forKey: haveMigratedKey)
        groupDefaults.set(true, forKey: haveMigratedKey)
    }

    fileprivate static func getUserDefaults() -> UserDefaults {
        if !AppGroupsHelper.isKumulosAppGroupDefined() {
            return UserDefaults.standard
        }

        if let suiteUserDefaults = UserDefaults(suiteName: AppGroupsHelper.getKumulosGroupName()) {
            return suiteUserDefaults
        }

        return UserDefaults.standard
    }
}

extension KeyValPersistenceHelper: KeyValPersistent {
    static func set(_ value: Any?, forKey: String) {
        getUserDefaults().set(value, forKey: forKey)
    }

    static func object(forKey: String) -> Any? {
        return getUserDefaults().object(forKey: forKey)
    }

    static func removeObject(forKey: String) {
        getUserDefaults().removeObject(forKey: forKey)
    }
}
