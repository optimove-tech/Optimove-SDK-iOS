//  Copyright © 2020 Optimove. All rights reserved.

import Foundation
import CoreData

protocol CoreDataMigratorProtocol {
    func requiresMigration(at storeURL: URL, toVersion version: CoreDataMigrationVersion) -> Bool
    func migrateStore(at storeURL: URL, toVersion version: CoreDataMigrationVersion) throws
}

final class CoreDataMigrator: CoreDataMigratorProtocol {

    func requiresMigration(at storeURL: URL,
                           toVersion version: CoreDataMigrationVersion) -> Bool {
        do {
            let metadata = try NSPersistentStoreCoordinator.metadata(at: storeURL)
            return (CoreDataMigrationVersion.compatibleVersionForStoreMetadata(metadata) != version)
        } catch {
            Logger.error(error.localizedDescription)
            return false
        }
    }

    func migrateStore(at storeURL: URL,
                      toVersion version: CoreDataMigrationVersion) throws {
        try forceWALCheckpointingForStore(at: storeURL)

        var currentURL = storeURL
        let migrationSteps = self.migrationStepsForStore(at: storeURL, toVersion: version)

        for migrationStep in migrationSteps {
            let manager = NSMigrationManager(sourceModel: migrationStep.sourceModel, destinationModel: migrationStep.destinationModel)

            /// Align managedObjectClassNames. On test this value clould be missed.
            if manager.destinationModel.entities[0].managedObjectClassName != migrationStep.destinationModel.entities[0].managedObjectClassName {
                manager.destinationModel.entities[0].managedObjectClassName = migrationStep.destinationModel.entities[0].managedObjectClassName
            }

            let destinationURL = URL(fileURLWithPath: NSTemporaryDirectory(), isDirectory: true).appendingPathComponent(UUID().uuidString)

            do {
                try manager.migrateStore(from: currentURL, sourceType: NSSQLiteStoreType, options: nil, with: migrationStep.mappingModel, toDestinationURL: destinationURL, destinationType: NSSQLiteStoreType, destinationOptions: nil)
            } catch {
                Logger.error("failed attempting to migrate from \(migrationStep.sourceModel) to \(migrationStep.destinationModel), error: \(error)")
                throw error
            }

            if currentURL != storeURL {
                //Destroy intermediate step's store
                try NSPersistentStoreCoordinator.destroyStore(at: currentURL)
            }

            currentURL = destinationURL
        }

        try NSPersistentStoreCoordinator.replaceStore(at: storeURL, withStoreAt: currentURL)

        if (currentURL != storeURL) {
            try NSPersistentStoreCoordinator.destroyStore(at: currentURL)
        }
    }

    private func migrationStepsForStore(at storeURL: URL, toVersion destinationVersion: CoreDataMigrationVersion) -> [CoreDataMigrationStep] {
        guard let metadata = try? NSPersistentStoreCoordinator.metadata(at: storeURL), let sourceVersion = CoreDataMigrationVersion.compatibleVersionForStoreMetadata(metadata) else {
            Logger.error("unknown store version at URL \(storeURL)")
            return []
        }

        return migrationSteps(fromSourceVersion: sourceVersion, toDestinationVersion: destinationVersion)
    }

    private func migrationSteps(fromSourceVersion sourceVersion: CoreDataMigrationVersion, toDestinationVersion destinationVersion: CoreDataMigrationVersion) -> [CoreDataMigrationStep] {
        var sourceVersion = sourceVersion
        var migrationSteps = [CoreDataMigrationStep]()

        while sourceVersion != destinationVersion, let nextVersion = sourceVersion.nextVersion() {
            let migrationStep = CoreDataMigrationStep(sourceVersion: sourceVersion, destinationVersion: nextVersion)
            migrationSteps.append(migrationStep)

            sourceVersion = nextVersion
        }

        return migrationSteps
    }

    // MARK: - WAL

    func forceWALCheckpointingForStore(at storeURL: URL) throws {
        let currentModel = CoreDataModelDescription.makeOptistreamEventModel(version: .version1)

        do {
            let persistentStoreCoordinator = NSPersistentStoreCoordinator(managedObjectModel: currentModel)

            let options = [NSSQLitePragmasOption: ["journal_mode": "DELETE"]]
            let store = try persistentStoreCoordinator.addPersistentStore(at: storeURL, options: options)
            try persistentStoreCoordinator.remove(store)
        } catch let error {
            Logger.error("failed to force WAL checkpointing, error: \(error)")
            throw error
        }
    }
}

private extension CoreDataMigrationVersion {

    static func compatibleVersionForStoreMetadata(_ metadata: [String : Any]) -> CoreDataMigrationVersion? {
        let compatibleVersion = CoreDataMigrationVersion.allCases.first { version in
            let model = CoreDataModelDescription.makeOptistreamEventModel(version: version)

            return model.isConfiguration(withName: nil, compatibleWithStoreMetadata: metadata)
        }

        return compatibleVersion
    }
}

extension NSPersistentStoreCoordinator {

    // MARK: - Destroy

    static func destroyStore(at storeURL: URL) throws {
        do {
            let persistentStoreCoordinator = NSPersistentStoreCoordinator(managedObjectModel: NSManagedObjectModel())
            try persistentStoreCoordinator.destroyPersistentStore(at: storeURL, ofType: NSSQLiteStoreType, options: nil)
        } catch {
            Logger.error("failed to destroy persistent store at \(storeURL), error: \(error)")
            throw error
        }
    }

    // MARK: - Replace

    static func replaceStore(at targetURL: URL, withStoreAt sourceURL: URL) throws {
        do {
            let persistentStoreCoordinator = NSPersistentStoreCoordinator(managedObjectModel: NSManagedObjectModel())
            try persistentStoreCoordinator.replacePersistentStore(at: targetURL, destinationOptions: nil, withPersistentStoreFrom: sourceURL, sourceOptions: nil, ofType: NSSQLiteStoreType)
        } catch {
            Logger.error("failed to replace persistent store at \(targetURL) with \(sourceURL), error: \(error)")
            throw error
        }
    }

    // MARK: - Meta

    static func metadata(at storeURL: URL) throws -> [String : Any]  {
        return try NSPersistentStoreCoordinator.metadataForPersistentStore(ofType: NSSQLiteStoreType, at: storeURL, options: nil)
    }

    // MARK: - Add

    func addPersistentStore(at storeURL: URL, options: [AnyHashable : Any]) throws -> NSPersistentStore {
        do {
            return try addPersistentStore(ofType: NSSQLiteStoreType, configurationName: nil, at: storeURL, options: options)
        } catch {
            Logger.error("failed to add persistent store to coordinator, error: \(error)")
            throw error
        }

    }
}
