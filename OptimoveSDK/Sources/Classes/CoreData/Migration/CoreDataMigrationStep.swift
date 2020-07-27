//  Copyright © 2020 Optimove. All rights reserved.

import Foundation
import CoreData

struct CoreDataMigrationStep {

    let sourceModel: NSManagedObjectModel
    let destinationModel: NSManagedObjectModel
    let mappingModel: NSMappingModel

    // MARK: Init

    init(sourceVersion: CoreDataMigrationVersion, destinationVersion: CoreDataMigrationVersion) {
        let sourceModel = CoreDataModelDescription.makeOptistreamEventModel(version: sourceVersion)
        let destinationModel = CoreDataModelDescription.makeOptistreamEventModel(version: destinationVersion)

        guard let mappingModel = CoreDataMigrationStep.mappingModel(
            fromSourceModel: sourceModel,
            toDestinationModel: destinationModel,
            destinationVersion: destinationVersion
        ) else {
            fatalError("Expected modal mapping not present")
        }

        self.sourceModel = sourceModel
        self.destinationModel = destinationModel
        self.mappingModel = mappingModel
    }

    // MARK: - Mapping

    private static func mappingModel(
        fromSourceModel sourceModel: NSManagedObjectModel,
        toDestinationModel destinationModel: NSManagedObjectModel,
        destinationVersion: CoreDataMigrationVersion
    ) -> NSMappingModel? {
        guard let customMapping = CoreDataCustomMappingModelFactory.make(for: destinationVersion) else {
            return inferredMappingModel(fromSourceModel:sourceModel, toDestinationModel: destinationModel)
        }
        return customMapping
    }

    private static func inferredMappingModel(
        fromSourceModel sourceModel: NSManagedObjectModel,
        toDestinationModel destinationModel: NSManagedObjectModel
    ) -> NSMappingModel? {
        return try? NSMappingModel.inferredMappingModel(forSourceModel: sourceModel, destinationModel: destinationModel)
    }
}
