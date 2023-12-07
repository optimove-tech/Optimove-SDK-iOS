//  Copyright © 2020 Optimove. All rights reserved.

import CoreData

/// Describes and creates`NSFetchedPropertyDescription`
struct CoreDataFetchedPropertyDescription {
    static func fetchedProperty(
        name: String,
        fetchRequest: NSFetchRequest<NSFetchRequestResult>,
        isOptional: Bool = false
    ) -> CoreDataFetchedPropertyDescription {
        return CoreDataFetchedPropertyDescription(
            name: name,
            fetchRequest: fetchRequest,
            isOptional: isOptional
        )
    }

    var name: String
    var fetchRequest: NSFetchRequest<NSFetchRequestResult>
    var isOptional: Bool

    func makeFetchedProperty() -> NSFetchedPropertyDescription {
        let fetchedProperty = NSFetchedPropertyDescription()
        fetchedProperty.name = name
        fetchedProperty.fetchRequest = fetchRequest
        fetchedProperty.isOptional = isOptional
        return fetchedProperty
    }
}
