//  Copyright © 2020 Optimove. All rights reserved.

import CoreData
import Foundation

enum CoreDataCustomMappingModelFactory {
    /// - Parameter destinationVersion: destinationVersion
    /// - Returns: Returns a mapping model for the passed destination version.
    static func make(for destinationVersion: CoreDataMigrationVersion) -> NSMappingModel? {
        switch destinationVersion {
        case .version1:
            return nil // Initial version
        case .version2:
            return EventCDv1ToEventCDv2MappingModelBuilder().build()
        }
    }
}

private final class EventCDv1ToEventCDv2MappingModelBuilder {
    func build() -> NSMappingModel {
        let entityMapping = NSEntityMapping()
        entityMapping.name = "EventCDv1ToEventCDv2"
        entityMapping.sourceExpression = NSExpression(
            format: "FETCH(FUNCTION($manager, \"fetchRequestForSourceEntityNamed:predicateString:\", \"EventCD\", \"TRUEPREDICATE\"), $manager.sourceContext, NO)"
        )
        entityMapping.sourceEntityName = EventCD.entityName
        entityMapping.destinationEntityName = EventCDv2.entityName
        entityMapping.mappingType = .customEntityMappingType
        entityMapping.entityMigrationPolicyClassName = NSStringFromClass(EventCDv1ToEventCDv2MigrationPolicy.self)

        let mappingModel = NSMappingModel()
        mappingModel.entityMappings = [entityMapping]

        return mappingModel
    }
}
