//  Copyright © 2022 Optimove. All rights reserved.

import Foundation

enum MediaHelper {
    /// Use ``Region.US`` as fallback region.
    static let mediaResizerBaseUrl: String = "https://i-us-east-1.app.delivery"

    static func getCompletePictureUrl(pictureUrl: String, width: UInt) -> URL? {
        if pictureUrl.hasPrefix("https://") || pictureUrl.hasPrefix("http://") {
            return URL(string: pictureUrl)
        }

        let baseUrl = KeyValPersistenceHelper.object(forKey: OptimobileUserDefaultsKey.MEDIA_BASE_URL.rawValue) as? String ?? mediaResizerBaseUrl

        let completeString = "\(baseUrl)/\(width)x/\(pictureUrl)"
        return URL(string: completeString)
    }
}
