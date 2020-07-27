//  Copyright © 2020 Optimove. All rights reserved.

import CoreData

struct CoreDataRelationshipDescription {

    static func relationship(
               name: String,
        destination: String,
           optional: Bool = true,
             toMany: Bool = false,
         deleteRule: NSDeleteRule = .nullifyDeleteRule,
            inverse: String? = nil) -> CoreDataRelationshipDescription {

        let maxCount = toMany ? 0 : 1

        return CoreDataRelationshipDescription(name: name, destination: destination, optional: optional, maxCount: maxCount, minCount: 0, deleteRule: deleteRule, inverse: inverse)
    }

    var name: String

    var destination: String

    var optional: Bool

    var maxCount: Int

    var minCount: Int

    var deleteRule: NSDeleteRule

    var inverse: String?
}

extension CoreDataRelationshipDescription {

    /// create a relationship from an NSManagedObject KeyPath, the inverse relationship another NSManagedObject KeyPath, and given delete rule
    static func relationship<Root, Value, InverseRoot, InverseValue>(_ keyPath: KeyPath<Root, Value>, inverse: KeyPath<InverseRoot, InverseValue>, deleteRule: NSDeleteRule = .nullifyDeleteRule) -> CoreDataRelationshipDescription where Root: NSManagedObject, InverseRoot: NSManagedObject {
        assert(keyPath.destinationType is NSManagedObject.Type)
        assert(inverse.destinationType is NSManagedObject.Type)

        return relationship(
            name: keyPath.stringValue,
            destination: "\(keyPath.destinationType)",
            optional: keyPath.isOptional,
            toMany: keyPath.isToMany,
            deleteRule: deleteRule,
            inverse: inverse.stringValue
        )
    }

    /// create a relationship from an NSManagedObject KeyPath and given delete rule
    static func relationship<Root, Value>(_ keyPath: KeyPath<Root, Value>, deleteRule: NSDeleteRule = .nullifyDeleteRule) -> CoreDataRelationshipDescription where Root: NSManagedObject {
        assert(keyPath.destinationType is NSManagedObject.Type)

        return relationship(
            name: keyPath.stringValue,
            destination: "\(keyPath.destinationType)",
            optional: keyPath.isOptional,
            toMany: keyPath.isToMany,
            deleteRule: deleteRule,
            inverse: nil
        )
    }
}
