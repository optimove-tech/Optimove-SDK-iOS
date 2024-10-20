//  Copyright © 2022 Optimove. All rights reserved.

import Foundation

public struct MediaHelper {
    enum Error: LocalizedError {
        case noMediaUrlFound
        case invalidPictureUrl(String)
    }

    let storage: KeyValueStorage

    public init(storage: KeyValueStorage) {
        self.storage = storage
    }

    public func getCompletePictureUrl(pictureUrlString: String, width: UInt) throws -> URL {
        if pictureUrlString.hasPrefix("https://") || pictureUrlString.hasPrefix("http://") {
            guard let url = URL(string: pictureUrlString) else {
                throw Error.invalidPictureUrl(pictureUrlString)
            }
            return url
        }

        guard let mediaUrl: String = storage[.mediaURL] else {
            throw Error.noMediaUrlFound
        }

        let urlString = "\(mediaUrl)/\(width)x/\(pictureUrlString)"
        guard let url = URL(string: urlString) else {
            throw Error.invalidPictureUrl(urlString)
        }

        return url
    }
}
