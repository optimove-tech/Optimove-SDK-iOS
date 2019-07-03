import AdSupport
import Foundation

class AdvertisingIdPermissionFetcher: Fetchable {
    func fetch(completionHandler: @escaping ResultBlockWithBool) {
        completionHandler(ASIdentifierManager.shared().isAdvertisingTrackingEnabled)
    }
}
