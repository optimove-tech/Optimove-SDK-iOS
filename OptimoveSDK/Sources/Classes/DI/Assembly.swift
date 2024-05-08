//  Copyright © 2020 Optimove. All rights reserved.

import Foundation
import OptimoveCore

final class Assembly {
    func makeContainer() -> Container {
        return Container(serviceLocator: makeServiceLocator())
    }

    private func makeServiceLocator() -> ServiceLocator? {
        /// A special storage migration, before an actual storage going to be in use.
        migrate()
        do {
            let keyValureStorage = try UserDefaults.optimove()
            let fileStorage = try FileStorageImpl(
                persistentStorageURL: FileManager.optimoveURL(),
                temporaryStorageURL: FileManager.temporaryURL()
            )
            return ServiceLocator(
                storageFacade: StorageFacade(
                    persistantStorage: keyValureStorage,
                    inMemoryStorage: InMemoryStorage(),
                    fileStorage: fileStorage
                )
            )
        } catch {
            Logger.error(error.localizedDescription)
            return nil
        }
    }

    private func migrate() {
        let migrations: [MigrationWork] = [
            MigrationWork_3_3_0(),
            MigrationWork_5_9_0()
        ]
        migrations
            .filter { $0.isAllowToMiragte(SDKVersion) }
            .forEach { $0.runMigration() }
    }
}
