

import Foundation
import AdSupport
class AdvertisingIdPermissionFetcher: Fetchable {
    func fetch(completionHandler: @escaping ResultBlockWithBool) {
        completionHandler(ASIdentifierManager.shared().isAdvertisingTrackingEnabled)
    }
}
