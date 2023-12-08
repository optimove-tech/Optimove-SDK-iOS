//  Copyright © 2023 Optimove. All rights reserved.

import OptimoveCore
import OptimoveTest
import XCTest

final class MediaHelperTests: XCTestCase {
    var mediaHelper: MediaHelper!
    var storage: KeyValueStorage!

    override func setUp() {
        storage = MockOptimoveStorage()
        mediaHelper = MediaHelper(storage: storage)
    }

    func test_getCompletePictureUrl() throws {
        let pictureUrlString = "https://www.optimove.com/wp-content/uploads/2018/12/optimove-logo.png"
        let url = try mediaHelper.getCompletePictureUrl(pictureUrlString: pictureUrlString, width: 100)
        XCTAssertEqual(url.absoluteString, pictureUrlString)
    }

    func test_getCompletePictureUrl_withMediaUrl() throws {
        let pictureUrlString = "B04wM4Y7/b2f69e254879d69b58c7418468213762.jpeg"
        let mediaUrl = "https://www.optimove.com"
        storage.set(value: mediaUrl, key: .mediaURL)
        let url = try mediaHelper.getCompletePictureUrl(pictureUrlString: pictureUrlString, width: 100)
        XCTAssertEqual(url.absoluteString, "\(mediaUrl)/100x/\(pictureUrlString)")
    }
}
