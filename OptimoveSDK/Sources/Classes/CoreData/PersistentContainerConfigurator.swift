//  Copyright © 2023 Optimove. All rights reserved.

import CoreData
import Foundation
import OptimoveCore

typealias ManagedObjectModel = NSManagedObjectModel

enum FileManagerLocation {
    case libraryDirectory
    case documentDirectory
    case appGroupDirectory(URL)
}

protocol PersistentContainerConfigurator {
    var folderName: String? { get }
    var modelName: String { get }
    var managedObjectModel: ManagedObjectModel { get }
    var location: FileManagerLocation { get }
}
