//  Copyright © 2020 Optimove. All rights reserved.

import Foundation

enum CoreDataMigrationVersion: String, CaseIterable {
    case version1 = "3.0.1"
    case version2 = "3.1.0"

    // MARK: - Current

    static var current: CoreDataMigrationVersion {
        guard let current = allCases.last else {
            fatalError("no model versions found")
        }

        return current
    }

    // MARK: - Migration

    func nextVersion() -> CoreDataMigrationVersion? {
        switch self {
        case .version1:
            return .version2
        case .version2:
            return nil
        }
    }
}
