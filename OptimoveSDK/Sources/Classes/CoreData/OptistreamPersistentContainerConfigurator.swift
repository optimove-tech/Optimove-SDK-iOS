//  Copyright © 2023 Optimove. All rights reserved.

import CoreData
import Foundation

final class OptistreamPersistentContainerConfigurator: PersistentContainerConfigurator {
    enum Constants {
        static let modelName = "OptistreamQueue"
        static let folderName = "com.optimove.sdk.no-backup"
    }

    let version: CoreDataMigrationVersion

    init(version: CoreDataMigrationVersion = .current) {
        self.version = version
    }

    let folderName: String = Constants.folderName
    let modelName: String = Constants.modelName
    var managedObjectModel: ManagedObjectModel {
        CoreDataModelDescription.makeOptistreamEventModel(version: version)
    }
}
