//  Copyright © 2022 Optimove. All rights reserved.

import Foundation

public enum MediaHelper {
    enum Error: LocalizedError {
        case noMediaUrlFound
        case invalidPictureUrl(String)
    }

    public static func getCompletePictureUrl(pictureUrlString: String, width: UInt) throws -> URL {
        if pictureUrlString.hasPrefix("https://") || pictureUrlString.hasPrefix("http://") {
            guard let url = URL(string: pictureUrlString) else {
                throw Error.invalidPictureUrl(pictureUrlString)
            }
            return url
        }

        guard let mediaUrl = KeyValPersistenceHelper.object(forKey: OptimobileUserDefaultsKey.MEDIA_BASE_URL.rawValue) as? String else {
            throw Error.noMediaUrlFound
        }

        let urlString = "\(mediaUrl)/\(width)x/\(pictureUrlString)"
        guard let url = URL(string: urlString) else {
            throw Error.invalidPictureUrl(urlString)
        }

        return url
    }
}
