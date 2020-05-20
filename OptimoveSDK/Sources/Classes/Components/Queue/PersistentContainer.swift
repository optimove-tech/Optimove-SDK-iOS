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

    init(modelName: String) {
        let mom = CoreDataModelDescription.makeOptistreamEventModel()
        super.init(name: modelName, managedObjectModel: mom)
    }

    func loadPersistentStores(storeName: String) throws {
        let persistentStoreDescription = NSPersistentStoreDescription()
        persistentStoreDescription.url = try defineStoreURL(storeName: storeName)
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
        let storeURL = try unwrap(libraryStoreDirectoryURL.appendingPathComponent("\(storeName).sqlite"))
        guard !fileManager.directoryExists(atUrl: libraryStoreDirectoryURL, isDirectory: true) else {
            return try fileManager.addSkipBackupAttributeToItemAtURL(url: storeURL)
        }
        try fileManager.createDirectory(at: libraryStoreDirectoryURL, withIntermediateDirectories: true)
        return try fileManager.addSkipBackupAttributeToItemAtURL(url: storeURL)
    }

}

extension FileManager {

    func addSkipBackupAttributeToItemAtURL(url: URL) throws -> URL {
        guard self.directoryExists(atUrl: url, isDirectory: false) else {
            return url
        }
        var url = url
        var resourceValues = URLResourceValues()
        resourceValues.isExcludedFromBackup = true
        try url.setResourceValues(resourceValues)
        return url
    }

    func directoryExists(atUrl url: URL, isDirectory: Bool) -> Bool {
        var isDirectory = ObjCBool(isDirectory)
        let exists = self.fileExists(atPath: url.path, isDirectory: &isDirectory)
        return exists && isDirectory.boolValue
    }
}

extension CoreDataModelDescription {

    static func makeOptistreamEventModel() -> NSManagedObjectModel {
        let modelDescription = CoreDataModelDescription(
            entities: [
                .entity(
                    name: String(describing: EventCD.self),
                    managedObjectClass: EventCD.self,
                    attributes: [
                        .attribute(name: #keyPath(EventCD.data), type: .binaryDataAttributeType),
                        .attribute(name: #keyPath(EventCD.date), type: .dateAttributeType),
                        .attribute(name: #keyPath(EventCD.type), type: .stringAttributeType),
                        .attribute(name: #keyPath(EventCD.uuid), type: .stringAttributeType)
                    ],
                    constraints: [#keyPath(EventCD.uuid), #keyPath(EventCD.type)]
                )
            ]
        )
        return modelDescription.makeModel()
    }
}
