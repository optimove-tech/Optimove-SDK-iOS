//  Copyright © 2020 Optimove. All rights reserved.

import Foundation
import CoreData

protocol Managed: NSObject, NSFetchRequestResult {
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
                      configurationBlock: (NSFetchRequest<Self>) -> Void = { _ in })  throws-> [Self] {
        let request = NSFetchRequest<Self>(entityName: Self.entityName)
        configurationBlock(request)
        return try context.fetch(request)
    }
}
