//  Copyright © 2023 Optimove. All rights reserved.

import Foundation

final class InAppPersistentContainerConfigurator: PersistentContainerConfigurator {
    enum Constants {
        static let modelName = "InAppMessages"
    }

    init() throws {
        let url = try FileManager.optimoveAppGroupURL()
        self.location = .appGroupDirectory(url)
    }

    var folderName: String? = nil
    let modelName: String = Constants.modelName
    var managedObjectModel: ManagedObjectModel =
        CoreDataModelDescription.makeInAppMessageModel()
    var location: FileManagerLocation
}
