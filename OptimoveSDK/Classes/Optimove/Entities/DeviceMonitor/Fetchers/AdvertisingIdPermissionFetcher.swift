import AdSupport
import Foundation

final class AdvertisingIdPermissionFetcher: Fetchable {

    func fetch(completion: @escaping ResultBlockWithBool) {
        completion(ASIdentifierManager.shared().isAdvertisingTrackingEnabled)
    }
}
