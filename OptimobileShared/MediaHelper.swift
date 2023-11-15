//  Copyright © 2022 Optimove. All rights reserved.

import Foundation

public class MediaHelper {
    private static let mediaResizerBaseUrl: String = "https://i.app.delivery"

    internal static func getCompletePictureUrl(pictureUrl: String, width: UInt) -> URL? {

        if (((pictureUrl as NSString).substring(with: NSRange(location: 0, length: 8))) == "https://") || (((pictureUrl as NSString).substring(with: NSRange(location: 0, length: 7))) == "http://") {
            return URL(string: pictureUrl)
        }

        let baseUrl = KeyValPersistenceHelper.object(forKey: OptimobileUserDefaultsKey.MEDIA_BASE_URL.rawValue) as? String ?? mediaResizerBaseUrl

        let completeString = String(format: "%@%@%ld%@%@", baseUrl, "/", width, "x/", pictureUrl)
        return URL(string: completeString)
    }
}
