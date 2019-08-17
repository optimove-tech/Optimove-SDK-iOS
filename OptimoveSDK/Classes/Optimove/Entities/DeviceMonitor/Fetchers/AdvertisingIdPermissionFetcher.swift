//  Copyright © 2019 Optimove. All rights reserved.

import AdSupport
import Foundation

final class AdvertisingIdPermissionFetcher: Fetchable {

    func fetch(completion: @escaping ResultBlockWithBool) {
        completion(ASIdentifierManager.shared().isAdvertisingTrackingEnabled)
    }
}
