//  Copyright © 2023 Optimove. All rights reserved.

@testable import OptimoveNotificationServiceExtension
import XCTest

final class OptimoveNotificationServiceExtensionTests: XCTestCase {
    func test_download_attachment() async throws {
        let url = URL(string: "https://picsum.photos/200")!
        let attachment = try await OptimoveNotificationService.downloadAttachment(url: url)
        XCTAssertNotNil(attachment)
        XCTAssertTrue(
            FileManager.default.fileExists(atPath: attachment.url.path),
            "File should exist at path: \(attachment.url.path)"
        )
    }

    func test_download_attachment_in_the_process() async throws {
        let url = URL(string: "https://picsum.photos/200")!
        for _ in 0 ... 10 {
            let attachment = try await OptimoveNotificationService.downloadAttachment(url: url)
            XCTAssertNotNil(attachment)
            XCTAssertTrue(
                FileManager.default.fileExists(atPath: attachment.url.path),
                "File should exist at path: \(attachment.url.path)"
            )
        }
    }

    func test_download_attachment_withInvalidUrl() async throws {
        let url = URL(string: "https://picsum.photos/invalid")!
        do {
            _ = try await OptimoveNotificationService.downloadAttachment(url: url)
            XCTFail("Should throw an error")
        } catch {
            XCTAssertNotNil(error)
        }
    }

    func test_getCompletePictureUrl() throws {
        let pictureUrlString = "https://www.optimove.com/wp-content/uploads/2018/12/optimove-logo.png"
        let url = try MediaHelper.getCompletePictureUrl(pictureUrlString: pictureUrlString, width: 100)
        XCTAssertEqual(url.absoluteString, pictureUrlString)
    }

    func test_getCompletePictureUrl_withMediaUrl() throws {
        let pictureUrlString = "B04wM4Y7/b2f69e254879d69b58c7418468213762.jpeg"
        let mediaUrl = "https://www.optimove.com"
        KeyValPersistenceHelper.set(mediaUrl, forKey: OptimobileUserDefaultsKey.MEDIA_BASE_URL.rawValue)
        let url = try MediaHelper.getCompletePictureUrl(pictureUrlString: pictureUrlString, width: 100)
        XCTAssertEqual(url.absoluteString, "\(mediaUrl)/100x/\(pictureUrlString)")
    }
}
