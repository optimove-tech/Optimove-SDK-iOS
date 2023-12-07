//  Copyright © 2020 Optimove. All rights reserved.

import CoreData

/// Describes `NSFetchIndexDescription`
struct CoreDataFetchIndexDescription {
    /// Describes `NSFetchIndexElementDescription`
    struct Element {
        enum Property {
            case property(name: String)
            case expression(type: String)
        }

        var property: Property
        var ascending: Bool

        static func property(name: String, ascending: Bool = true) -> Element {
            Element(property: .property(name: name), ascending: ascending)
        }
    }

    var name: String
    var elements: [Element]

    static func index(name: String, elements: [Element]) -> CoreDataFetchIndexDescription {
        CoreDataFetchIndexDescription(name: name, elements: elements)
    }
}
