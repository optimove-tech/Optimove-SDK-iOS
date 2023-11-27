//  Copyright © 2020 Optimove. All rights reserved.

import CoreData
@testable import OptimoveSDK
import OptimoveTest
import XCTest

class CoreDataMigratorTests: XCTestCase {
    var migrator: CoreDataMigrator!

    override func setUpWithError() throws {
        super.setUp()

        FileManager.clearTempDirectoryContents()
        migrator = CoreDataMigrator()
    }

    override func tearDownWithError() throws {
        migrator = nil
    }

    func tearDownCoreDataStack(context: NSManagedObjectContext) {
        context.destroyStore()
    }

    func testExample() throws {
        let sourceURL = FileManager.moveFileFromBundleToTempDirectory(filename: "Events-2590.sqlite")
        let toVersion = CoreDataMigrationVersion.version2

        try migrator.migrateStore(at: sourceURL, toVersion: toVersion)

        XCTAssertTrue(FileManager.default.fileExists(atPath: sourceURL.path))

        let model = CoreDataModelDescription.makeOptistreamEventModel(version: toVersion)
        let context = NSManagedObjectContext(model: model, storeURL: sourceURL)
        let migratedPosts = try EventCDv2.fetch(in: context) { request in
            request.predicate = EventCDv2.queueTypePredicate(queueType: .track)
            request.sortDescriptors = EventCDv2.defaultSortDescriptors
            request.fetchLimit = 50
            request.returnsObjectsAsFaults = false
        }

        XCTAssertEqual(migratedPosts.count, 10)

        let migratedPost = migratedPosts[0]
        XCTAssertNoThrow(try JSONDecoder().decode(OptistreamEvent.self, from: migratedPost.data))
        tearDownCoreDataStack(context: context)
    }
}

extension FileManager {
    // MARK: - Temp

    static func clearTempDirectoryContents() {
        let tmpDirectoryContents = try! FileManager.default.contentsOfDirectory(atPath: NSTemporaryDirectory())
        tmpDirectoryContents.forEach {
            let fileURL = URL(fileURLWithPath: NSTemporaryDirectory(), isDirectory: true).appendingPathComponent($0)
            try? FileManager.default.removeItem(atPath: fileURL.path)
        }
    }

    static func moveFileFromBundleToTempDirectory(filename: String) -> URL {
        let destinationURL = URL(fileURLWithPath: NSTemporaryDirectory(), isDirectory: true).appendingPathComponent(filename)
        try? FileManager.default.removeItem(at: destinationURL)
        let bundleURL = Bundle.mypackageResources.resourceURL!.appendingPathComponent(filename)
        try? FileManager.default.copyItem(at: bundleURL, to: destinationURL)

        return destinationURL
    }
}

extension NSManagedObjectContext {
    // MARK: Model

    convenience init(model: NSManagedObjectModel, storeURL: URL) {
        let persistentStoreCoordinator = NSPersistentStoreCoordinator(managedObjectModel: model)
        try! persistentStoreCoordinator.addPersistentStore(ofType: NSSQLiteStoreType, configurationName: nil, at: storeURL, options: nil)

        self.init(concurrencyType: .mainQueueConcurrencyType)

        self.persistentStoreCoordinator = persistentStoreCoordinator
    }

    // MARK: - Destroy

    func destroyStore() {
        persistentStoreCoordinator?.persistentStores.forEach {
            try? persistentStoreCoordinator?.remove($0)
            try? persistentStoreCoordinator?.destroyPersistentStore(at: $0.url!, ofType: $0.type, options: nil)
        }
    }
}
