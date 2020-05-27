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
        version: Version
    ) {
        self.storage = storage
        self.version = version
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

final class MigrationWork_2_10_0: MigrationWorker {

    private let synchronizer: Synchronizer

    init(synchronizer: Synchronizer,
         storage: OptimoveStorage) {
        self.synchronizer = synchronizer
        super.init(storage: storage, version: .v_2_10_0)
    }

    override func runMigration() {
        synchronizer.handle(.setInstallation)
        storage.finishedMigration(to: version.rawValue)
    }

}

final class MigrationWork_3_0_0: MigrationWorker {

    init(storage: OptimoveStorage) {
        super.init(storage: storage, version: .v_3_0_0)
    }

    override func runMigration() {
        if storage.firstRunTimestamp == nil {
            storage.firstRunTimestamp = storage.firstVisitTimestamp
        }
        storage.finishedMigration(to: version.rawValue)
    }

}
