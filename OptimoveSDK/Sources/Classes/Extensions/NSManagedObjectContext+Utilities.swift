//  Copyright © 2020 Optimove. All rights reserved.

import CoreData
import OptimoveCore

extension NSManagedObjectContext {

    /**
     Safe is determined by checking if the context has any persistent stores.
     - Returns: `False` if no persistent stores found.
     */
    private var isSafe: Bool {
        return (persistentStoreCoordinator?.persistentStores.count ?? 0) > 0
    }

    /**
     Performs a synchronous block with the passed in boolean indicating if it's safe to perform
     operations. Safe is determined by checking if the context has any persistent stores. Throws an error if occurs.
     - Parameters:
        - block: A block to perform.
     - Returns: A value with generic type.
     */
    func safeTryPerformAndWait<T>(_ block: (Bool) throws -> T) throws -> T {
        var result: Result<T, Error>?
        performAndWait {
            result = Result { try block(isSafe) }
        }
        return try result!.get()
    }

    /**
     Performs a synchronous block with the passed in boolean indicating if it's safe to perform
     operations. Safe is determined by checking if the context has any persistent stores. Throws an error if occurs.
     - Parameters:
        - block: A block to perform.
     */
    func safeTryPerformAndWait(_ block: (Bool) throws -> Void) throws {
        var result: Result<Void, Error>?
        performAndWait {
            result = Result { try block(isSafe) }
        }
        try result!.get()
    }

    /**
     Performs a synchronous block with the passed in boolean indicating if it's safe to perform
     operations. Safe is determined by checking if the context has any persistent stores.
     - Parameters:
        - block: A block to perform.
     */
    func safePerformAndWait(_ block: (Bool) -> Void) {
        performAndWait {
            block(isSafe)
        }
    }

    /**
     Performs a save.
     Catches the exception that might be thrown from the save call and rolls back the pending changes in the error case, i.e. it simply abandons the unsaved data.
     */
    func safeSaveOrRollback() {
        guard !isSafe else {
            Logger.error("Unable to save context. Missing persistent store.")
            return
        }
        performAndWait {
            guard hasChanges else { return }
            do {
                try save()
            } catch {
                rollback()
            }
        }
    }

    /**
     Performs an asynchronous block with the passed in boolean indicating if it's safe to perform
     operations. Safe is determined by checking if the context has any persistent stores.
     - Parameters:
        - block: A block to perform.
     */
    func safePerformChanges(block: @escaping (Bool) -> Void) {
        perform {
            block(self.isSafe)
        }
    }

    /**
     Insert new objects without having to manually downcast the result every time, and without having to reference the entity type by its name.
     - Returns: A `Managed` object.
     */
    func insertObject<A: NSManagedObject>() throws -> A where A: Managed {
        guard let obj = NSEntityDescription.insertNewObject(forEntityName: A.entityName, into: self) as? A else {
            throw GuardError.custom("Wrong object type for entity name: \(A.entityName)")
        }
        return obj
    }
}
