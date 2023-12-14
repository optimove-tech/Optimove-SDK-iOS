//  Copyright © 2023 Optimove. All rights reserved.

import CoreData
import Foundation
import OptimoveCore

typealias ManagedObjectModel = NSManagedObjectModel

protocol PersistentContainerConfigurator {
    var folderName: String { get }
    var modelName: String { get }
    var managedObjectModel: ManagedObjectModel { get }
}
