//  Copyright © 2020 Optimove. All rights reserved.

import Foundation
import CoreData
import OptimoveCore

struct PersistantModelNames {
    static let optistream = "OptistreamQueue"
}

final class PersistentContainer: NSPersistentContainer {

    private struct Constants {
        static let folderName = "com.optimove.sdk.no-backup"
    }

    init(modelName: String) throws {
        do {
            let bundle = Bundle.init(for: type(of: self))
            let url = try unwrap(bundle.url(forResource: modelName, withExtension: "momd"))
            let moc = try unwrap(NSManagedObjectModel.init(contentsOf: url))
            super.init(name: modelName, managedObjectModel: moc)
        } catch {
            Logger.error(error.localizedDescription)
            throw error
        }
    }

    func loadPersistentStores(storeName: String) throws {
        let persistentStoreDescription = NSPersistentStoreDescription()
        let storeURL = try defineStoreURL(storeName: storeName)
        persistentStoreDescription.url = try addSkipBackupAttributeToItemAtURL(url: storeURL)
        self.persistentStoreDescriptions = [persistentStoreDescription]
        self.loadPersistentStores { description, error in
            if let error = error {
                Logger.error("Unable to load persistent stores: \(error)")
            }
        }
    }
}

private extension PersistentContainer {

    func defineStoreURL(storeName: String) throws -> URL {
        let fileManager = FileManager.default
        let libraryDirectory = try unwrap(fileManager.urls(for: .libraryDirectory, in: .userDomainMask).first)
        let libraryStoreDirectoryURL = try unwrap(libraryDirectory.appendingPathComponent(Constants.folderName))
        return try unwrap(libraryStoreDirectoryURL.appendingPathComponent("\(storeName).sqlite"))
    }

    func addSkipBackupAttributeToItemAtURL(url: URL) throws -> URL {
        var url = url
        var resourceValues = URLResourceValues()
        resourceValues.isExcludedFromBackup = true
        try url.setResourceValues(resourceValues)
        return url
    }
}
