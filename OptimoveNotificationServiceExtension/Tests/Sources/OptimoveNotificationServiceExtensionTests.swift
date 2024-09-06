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
}
