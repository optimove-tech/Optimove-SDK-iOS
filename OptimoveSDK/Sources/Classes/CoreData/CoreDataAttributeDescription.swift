//  Copyright © 2020 Optimove. All rights reserved.

import CoreData

/// Describes and creates`NSAttributeDescription`
struct CoreDataAttributeDescription {

    static func attribute(
        name: String,
        type: NSAttributeType,
        isOptional: Bool = false,
        defaultValue: Any? = nil,
        isIndexedBySpotlight: Bool = false
    ) -> CoreDataAttributeDescription {
        return CoreDataAttributeDescription(
            name: name,
            attributeType: type,
            isOptional: isOptional,
            defaultValue: defaultValue,
            isIndexedBySpotlight: isIndexedBySpotlight
        )
    }

    var name: String
    var attributeType: NSAttributeType
    var isOptional: Bool
    var defaultValue: Any?
    var isIndexedBySpotlight: Bool

    func makeAttribute() -> NSAttributeDescription {
        let attribute = NSAttributeDescription()
        attribute.name = name
        attribute.attributeType = attributeType
        attribute.isOptional = isOptional
        attribute.defaultValue = defaultValue
        attribute.isIndexedBySpotlight = isIndexedBySpotlight

        return attribute
    }
}
