//  Copyright © 2020 Optimove. All rights reserved.

import OptimoveCore

protocol MigrationWork {
    func isAllowToMiragte(_ currentVersion: String) -> Bool
    func runMigration()
}

final class MigrationWork_2_10_0: MigrationWork {

    private let version: Version = .v_2_10_0
    private let synchronizer: Synchronizer
    private var storage: OptimoveStorage

    init(synchronizer: Synchronizer,
         storage: OptimoveStorage) {
        self.synchronizer = synchronizer
        self.storage = storage
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

    func runMigration() {
        synchronizer.handle(.setUserId)
        storage.finishedMigration(to: version.rawValue)
    }

}
