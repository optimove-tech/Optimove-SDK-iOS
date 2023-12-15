//  Copyright © 2020 Optimove. All rights reserved.

import CoreData
import Foundation

protocol Managed: AnyObject, NSFetchRequestResult {
    static var entityName: String { get }
    static var defaultSortDescriptors: [NSSortDescriptor] { get }
}

extension Managed {
    static var defaultSortDescriptors: [NSSortDescriptor] {
        return []
    }

    static var sortedFetchRequest: NSFetchRequest<Self> {
        let request = NSFetchRequest<Self>(entityName: entityName)
        request.sortDescriptors = defaultSortDescriptors
        return request
    }
}

extension Managed where Self: NSManagedObject {
    static func fetch(in context: NSManagedObjectContext,
                      configurationBlock: (NSFetchRequest<Self>) -> Void = { _ in }) throws -> [Self]
    {
        let request = NSFetchRequest<Self>(entityName: Self.entityName)
        configurationBlock(request)
        return try context.fetch(request)
    }

    static func delete(
        in context: NSManagedObjectContext,
        configurationBlock: (NSFetchRequest<NSFetchRequestResult>) -> Void = { _ in }
    ) throws {
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: Self.entityName)
        configurationBlock(fetchRequest)
        let deleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)
        try context.execute(deleteRequest)
    }
}
