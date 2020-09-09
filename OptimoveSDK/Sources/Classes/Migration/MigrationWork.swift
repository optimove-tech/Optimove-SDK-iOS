//  Copyright © 2020 Optimove. All rights reserved.

import OptimoveCore

protocol MigrationWork {
    func isAllowToMiragte(_ currentVersion: String) -> Bool
    func runMigration()
}

class MigrationWorker: MigrationWork {

    fileprivate let version: Version
    fileprivate var storage: OptimoveStorage

    init(
        storage: OptimoveStorage,
        newVersion: Version
    ) {
        self.storage = storage
        self.version = newVersion
    }

    func isAllowToMiragte(_ currentVersion: String) -> Bool {
        guard !storage.isAlreadyMigrated(to: currentVersion) else {
            return false
        }
        switch version.rawValue.compare(currentVersion, options: .numeric) {
        case .orderedSame, .orderedAscending:
            return true
        default:
            return false
        }
    }

    func runMigration() {}
}

class MigrationWorkerBase: MigrationWorker {

    /// Have call `super.runMigration()` in an overrided method.
    override func runMigration() {
        storage.finishedMigration(to: version.rawValue)
    }

}

final class MigrationWork_2_10_0: MigrationWorkerBase {

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

final class MigrationWork_3_0_0: MigrationWorkerBase {

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

final class MigrationWork_3_4_0: MigrationWorkerBase {

    init(storage: OptimoveStorage) {
        super.init(storage: storage, newVersion: .v_3_4_0)
    }

    override func runMigration() {
        let replacers: [Replacer] = [
            AppGroupReplacer(),
            UserDefaultsReplacer()
        ]
        replacers.forEach { $0.replace() }
        super.runMigration()
    }

}

private protocol Replacer {
    func replace()
}

extension MigrationWork_3_4_0 {

    final class AppGroupReplacer: Replacer {
        func replace() {
            // TODO: Merge appgroup values to UserDefaults.shared, also move files to the main container!
        }
    }

    final class UserDefaultsReplacer: Replacer {
        func replace() {
            // TODO: Allocate a new, optimove own, UserDefaults plist and move all the data from UserDefaults.shared
        }
    }

}
