//  Copyright © 2020 Optimove. All rights reserved.

import OptimoveCore
import UIKit

final class InstallationIdGenerator {
    private var storage: OptimoveStorage

    init(storage: OptimoveStorage) {
        self.storage = storage
    }

    func generate() {
        guard storage.installationID == nil else { return }
        var installationID = UUID().uuidString
        /// The migration logic to start using an unique UUID instead of the VendorID.
        /// The non-empty Initial Visitor ID as marker of an upgrade.
        if storage.initialVisitorId != nil, let vendorId = UIDevice.current.identifierForVendor?.uuidString.sha1() {
            installationID = vendorId
        }
        storage.installationID = installationID
    }
}
