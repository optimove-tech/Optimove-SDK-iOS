//  Copyright © 2020 Optimove. All rights reserved.

import CoreData

/// Describes and creates `NSEntityDescription`
struct CoreDataEntityDescription {
    static func entity(
        name: String,
        managedObjectClass: NSManagedObject.Type = NSManagedObject.self,
        parentEntity: String? = nil,
        isAbstract: Bool = false,
        attributes: [CoreDataAttributeDescription] = [],
        fetchedProperties: [CoreDataFetchedPropertyDescription] = [],
        relationships: [CoreDataRelationshipDescription] = [],
        indexes: [CoreDataFetchIndexDescription] = [],
        constraints: [Any] = [],
        configuration: String? = nil
    ) -> CoreDataEntityDescription {
        CoreDataEntityDescription(
            name: name,
            managedObjectClassName: String(describing: managedObjectClass),
            parentEntity: parentEntity,
            isAbstract: isAbstract,
            attributes: attributes,
            fetchedProperties: fetchedProperties,
            relationships: relationships,
            indexes: indexes,
            constraints: constraints,
            configuration: configuration
        )
    }

    var name: String
    var managedObjectClassName: String
    var parentEntity: String?
    var isAbstract: Bool
    var attributes: [CoreDataAttributeDescription]
    var fetchedProperties: [CoreDataFetchedPropertyDescription]
    var relationships: [CoreDataRelationshipDescription]
    var indexes: [CoreDataFetchIndexDescription]
    var constraints: [Any]
    var configuration: String?
}
