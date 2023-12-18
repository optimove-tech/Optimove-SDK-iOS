//  Copyright © 2020 Optimove. All rights reserved.

import CoreData
import Foundation
import OptimoveCore

final class PersistentContainer: NSPersistentContainer {
    enum PersistentStoreType {
        case sql
        case inMemory

        var coreDataValue: String {
            switch self {
            case .sql:
                return NSSQLiteStoreType
            case .inMemory:
                return NSInMemoryStoreType
            }
        }
    }

    private let migrator: CoreDataMigratorProtocol
    private let persistentContainerConfigurator: PersistentContainerConfigurator
    private let storeType: PersistentStoreType

    init(
        persistentContainerConfigurator: PersistentContainerConfigurator,
        migrator: CoreDataMigratorProtocol = CoreDataMigrator(),
        storeType: PersistentStoreType = .sql
    ) {
        self.migrator = migrator
        self.storeType = storeType
        self.persistentContainerConfigurator = persistentContainerConfigurator
        super.init(
            name: persistentContainerConfigurator.modelName,
            managedObjectModel: persistentContainerConfigurator.managedObjectModel
        )
    }

    func loadPersistentStores(storeName: String) throws {
        guard !isThisStoreAlreadyLoaded(storeName: storeName) else { return }
        let persistentStoreDescription = NSPersistentStoreDescription()
        persistentStoreDescription.type = storeType.coreDataValue
        persistentStoreDescription.url = try FileManager.default.defineStoreURL(
            location: persistentContainerConfigurator.location,
            folderName: persistentContainerConfigurator.folderName,
            storeName: storeName
        )
        persistentStoreDescription.shouldMigrateStoreAutomatically = false
        persistentStoreDescription.shouldInferMappingModelAutomatically = false
        persistentStoreDescriptions = [persistentStoreDescription]
        migrateStoreIfNeeded {
            self.loadPersistentStores { _, error in
                if let error = error {
                    Logger.error("Unable to load persistent stores: \(error)")
                }
            }
        }
    }

    private func migrateStoreIfNeeded(completion: @escaping () -> Void) {
        guard let storeURL = persistentStoreDescriptions.first?.url else {
            Logger.error("persistentContainer was not set up properly")
            completion()
            return
        }

        if migrator.requiresMigration(at: storeURL, toVersion: CoreDataMigrationVersion.current) {
            DispatchQueue.global(qos: .userInitiated).async {
                do {
                    try self.migrator.migrateStore(at: storeURL, toVersion: CoreDataMigrationVersion.current)
                } catch {
                    Logger.error(error.localizedDescription)
                }
                DispatchQueue.main.async {
                    completion()
                }
            }
        } else {
            completion()
        }
    }

    private func isThisStoreAlreadyLoaded(storeName: String) -> Bool {
        return !persistentStoreDescriptions.compactMap { psd in
            psd.url?.deletingPathExtension().lastPathComponent
        }.filter { $0 == storeName }.isEmpty
    }
}

extension FileManager {
    func defineLocation(_ location: FileManagerLocation) throws -> URL {
        switch location {
        case let .appGroupDirectory(url):
            return url
        case .documentDirectory:
            return try unwrap(urls(for: .documentDirectory, in: .userDomainMask).first)
        case .libraryDirectory:
            return try unwrap(urls(for: .libraryDirectory, in: .userDomainMask).first)
        }
    }

    func defineStoreURL(
        location: FileManagerLocation,
        folderName: String?,
        storeName: String
    ) throws -> URL {
        let storeFolderURL = try {
            let locationURL = try defineLocation(location)
            if let folderName = folderName {
                return try unwrap(locationURL.appendingPathComponent(folderName))
            }
            return locationURL
        }()
        let storeURL = try unwrap(storeFolderURL.appendingPathComponent("\(storeName).sqlite"))
        guard !directoryExists(atUrl: storeFolderURL, isDirectory: true) else {
            return try addSkipBackupAttributeToItemAtURL(url: storeURL)
        }
        try createDirectory(at: storeFolderURL, withIntermediateDirectories: true)
        return try addSkipBackupAttributeToItemAtURL(url: storeURL)
    }

    func addSkipBackupAttributeToItemAtURL(url: URL) throws -> URL {
        guard directoryExists(atUrl: url, isDirectory: false) else {
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
        let exists = fileExists(atPath: url.path, isDirectory: &isDirectory)
        return exists && isDirectory.boolValue
    }
}

extension CoreDataModelDescription {
    static func makeOptistreamEventModel(version: CoreDataMigrationVersion) -> NSManagedObjectModel {
        switch version {
        case .version1:
            return makeOptistreamEventModelv1()
        case .version2:
            return makeOptistreamEventModelv2()
        }
    }

    static func makeAnalyticsEventModel() -> NSManagedObjectModel {
        return makeAnalyticsEventModelv1()
    }

    static func makeInAppMessageModel() -> NSManagedObjectModel {
        let modelDescription = CoreDataModelDescription(
            entities: [
                .entity(
                    name: InAppMessageEntity.entityName,
                    managedObjectClass: InAppMessageEntity.self,
                    attributes: [
                        .attribute(
                            name: #keyPath(InAppMessageEntity.id),
                            type: .integer64AttributeType
                        ),
                        .attribute(
                            name: #keyPath(InAppMessageEntity.updatedAt),
                            type: .dateAttributeType
                        ),
                        .attribute(
                            name: #keyPath(InAppMessageEntity.presentedWhen),
                            type: .stringAttributeType
                        ),
                        .attribute(
                            name: #keyPath(InAppMessageEntity.content),
                            type: .binaryDataAttributeType
                        ),
                        .attribute(
                            name: #keyPath(InAppMessageEntity.data),
                            type: .binaryDataAttributeType,
                            isOptional: true
                        ),
                        .attribute(
                            name: #keyPath(InAppMessageEntity.badgeConfig),
                            type: .binaryDataAttributeType,
                            isOptional: true
                        ),
                        .attribute(
                            name: #keyPath(InAppMessageEntity.inboxConfig),
                            type: .binaryDataAttributeType,
                            isOptional: true
                        ),
                        .attribute(
                            name: #keyPath(InAppMessageEntity.inboxFrom),
                            type: .dateAttributeType,
                            isOptional: true
                        ),
                        .attribute(
                            name: #keyPath(InAppMessageEntity.inboxTo),
                            type: .dateAttributeType,
                            isOptional: true
                        ),
                        .attribute(
                            name: #keyPath(InAppMessageEntity.dismissedAt),
                            type: .dateAttributeType,
                            isOptional: true
                        ),
                        .attribute(
                            name: #keyPath(InAppMessageEntity.expiresAt),
                            type: .dateAttributeType,
                            isOptional: true
                        ),
                        .attribute(
                            name: #keyPath(InAppMessageEntity.readAt),
                            type: .dateAttributeType,
                            isOptional: true
                        ),
                        .attribute(
                            name: #keyPath(InAppMessageEntity.sentAt),
                            type: .dateAttributeType,
                            isOptional: true
                        ),
                    ]
                ),
            ]
        )
        return modelDescription.makeModel()
    }

    private static func makeOptistreamEventModelv1() -> NSManagedObjectModel {
        let modelDescription = CoreDataModelDescription(
            entities: [
                .entity(
                    name: EventCD.entityName,
                    managedObjectClass: EventCD.self,
                    attributes: [
                        .attribute(name: #keyPath(EventCD.data), type: .binaryDataAttributeType),
                        .attribute(name: #keyPath(EventCD.type), type: .stringAttributeType),
                        .attribute(name: #keyPath(EventCD.uuid), type: .stringAttributeType),
                        .attribute(name: #keyPath(EventCD.date), type: .stringAttributeType),
                    ],
                    constraints: [#keyPath(EventCD.uuid), #keyPath(EventCD.type)]
                ),
            ]
        )
        return modelDescription.makeModel()
    }

    private static func makeOptistreamEventModelv2() -> NSManagedObjectModel {
        let modelDescription = CoreDataModelDescription(
            entities: [
                .entity(
                    name: EventCDv2.entityName,
                    managedObjectClass: EventCDv2.self,
                    attributes: [
                        .attribute(name: #keyPath(EventCDv2.data), type: .binaryDataAttributeType),
                        .attribute(name: #keyPath(EventCDv2.type), type: .stringAttributeType),
                        .attribute(name: #keyPath(EventCDv2.eventId), type: .stringAttributeType),
                        .attribute(
                            name: #keyPath(EventCDv2.creationDate),
                            type: .dateAttributeType,
                            defaultValue: Date()
                        ),
                    ],
                    constraints: [#keyPath(EventCDv2.eventId), #keyPath(EventCDv2.type)]
                ),
            ]
        )
        return modelDescription.makeModel()
    }

    private static func makeAnalyticsEventModelv1() -> NSManagedObjectModel {
        let modelDescription = CoreDataModelDescription(
            entities: [
                .entity(
                    name: KSEventModel.entityName,
                    managedObjectClass: KSEventModel.self,
                    attributes: [
                        .attribute(
                            name: #keyPath(KSEventModel.eventType),
                            type: .stringAttributeType
                        ),
                        .attribute(
                            name: #keyPath(KSEventModel.happenedAt),
                            type: .integer64AttributeType,
                            defaultValue: 0
                        ),
                        .attribute(
                            name: #keyPath(KSEventModel.properties),
                            type: .binaryDataAttributeType,
                            isOptional: true
                        ),
                        .attribute(
                            name: #keyPath(KSEventModel.uuid),
                            type: .stringAttributeType
                        ),
                        .attribute(
                            name: #keyPath(KSEventModel.userIdentifier),
                            type: .stringAttributeType,
                            isOptional: true
                        ),
                    ]
                ),
            ]
        )
        return modelDescription.makeModel()
    }
}
