//  Copyright © 2020 Optimove. All rights reserved.

import CoreData
import OptimoveCore

extension NSManagedObjectContext {

    func performAndWait<T>(_ block: () throws -> T) throws -> T {
        var result: Result<T, Error>?
        performAndWait {
            result = Result { try block() }
        }
        return try result!.get()
    }

    func insertObject<A: NSManagedObject>() throws -> A where A: Managed {
        guard let obj = NSEntityDescription.insertNewObject(forEntityName: A.entityName, into: self) as? A else {
            throw GuardError.custom("Wrong object type")
        }
        return obj
    }

    func saveOrRollback() {
        guard hasChanges else { return }
        do {
            try save()
        } catch {
            rollback()
        }
    }

    func performChanges(block: @escaping () -> ()) {
        perform {
            block()
            self.saveOrRollback()
        }
    }
}
