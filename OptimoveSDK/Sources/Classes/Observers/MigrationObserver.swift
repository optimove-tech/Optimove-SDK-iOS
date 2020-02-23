//  Copyright © 2020 Optimove. All rights reserved.

final class MigrationObserver {

    private let migrationWorks: [MigrationWork]

    init(migrationWorks: [MigrationWork]) {
        self.migrationWorks = migrationWorks
    }

}

extension MigrationObserver: DeviceStateObservable {

    func observe() {
        let version = Optimove.version
        migrationWorks.filter{$0.isAllowToMiragte(version)}.forEach{$0.runMigration()}
    }

}
