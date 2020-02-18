//  Copyright © 2020 Optimove. All rights reserved.

import Foundation
import OptimoveCore

final class Assembly {

    func makeContainer() -> Container {
        return Container(serviceLocator: makeServiceLocator())
    }

    private func makeServiceLocator() -> ServiceLocator? {
        do {
            let bundleIdentifier = try Bundle.getApplicationNameSpace()
            let groupStorage = try UserDefaults.grouped(tenantBundleIdentifier: bundleIdentifier)
            let fileStorage = try FileStorageImpl(bundleIdentifier: bundleIdentifier, fileManager: .default)
            return ServiceLocator(
                storageFacade: StorageFacade(
                    groupedStorage: groupStorage,
                    sharedStorage: UserDefaults.standard,
                    fileStorage: fileStorage
                )
            )
        } catch {
            Logger.error(error.localizedDescription)
            return nil
        }
    }

}
