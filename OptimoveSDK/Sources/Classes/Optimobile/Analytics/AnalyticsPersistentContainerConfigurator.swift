//  Copyright © 2023 Optimove. All rights reserved.

import Foundation

final class AnalyticsPersistentContainerConfigurator: PersistentContainerConfigurator {
    enum Constants {
        static let modelName = "AnalyticsEvents"
    }

    init() throws {
        let url = try FileManager.optimoveAppGroupURL()
        self.location = .appGroupDirectory(url)
    }

    var folderName: String? = nil
    let modelName: String = Constants.modelName
    var managedObjectModel: ManagedObjectModel =
        CoreDataModelDescription.makeAnalyticsEventModel()
    var location: FileManagerLocation
}
