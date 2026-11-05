//  Copyright © 2026 Optimove. All rights reserved.

import XCTest
@testable import OptimoveSDK

private class UnusedHttpClient: KSHttpClient {
    func sendRequest(_ method: KSHttpMethod, toPath path: String, data: Any?, authUserId: String?, onSuccess: @escaping KSHttpSuccessBlock, onFailure: @escaping KSHttpFailureBlock) {}
    func invalidateSessionCancellingTasks(_ cancel: Bool) {}
}

final class OverlayMessagingRequestServiceTests: XCTestCase {

    // MARK: - parseScheduledResponse

    func test_parsesTheFirstMessageAsScheduled() {
        let body: [AnyHashable: Any] = [
            "messages": [["id": 7, "content": ["ver": 1, "html": "<p>hi</p>"], "data": ["k": "v"]]],
            "nextFetchInSeconds": 0,
        ]

        let result = OverlayMessagingRequestService.parseScheduledResponse(body)

        XCTAssertEqual(result?.message?.id, 7)
        XCTAssertEqual(result?.message?.content["html"] as? String, "<p>hi</p>")
        XCTAssertEqual(result?.message?.data?["k"] as? String, "v")
        XCTAssertEqual(result?.message?.type, .session)
        XCTAssertEqual(result?.nextFetchInSeconds, 0)
    }

    func test_parsesNoMessageWithTheServersNextFetch() {
        let result = OverlayMessagingRequestService.parseScheduledResponse(["messages": [], "nextFetchInSeconds": 2040])

        XCTAssertNotNil(result)
        XCTAssertNil(result?.message)
        XCTAssertEqual(result?.nextFetchInSeconds, 2040)
    }

    func test_rejectsABodyWithoutNextFetch() {
        XCTAssertNil(OverlayMessagingRequestService.parseScheduledResponse(["messages": []]))
        XCTAssertNil(OverlayMessagingRequestService.parseScheduledResponse(nil))
    }

    // MARK: - retry backoff

    func test_retriesAfterOneMinuteDoublingUpToAnHour() {
        let service = OverlayMessagingRequestService(httpClient: UnusedHttpClient())

        for seconds: Int64 in [60, 120, 240, 480, 960, 1920, 3600, 3600] {
            let result = service.retryLater()
            XCTAssertNil(result.message)
            XCTAssertEqual(result.nextFetchInSeconds, seconds)
        }
    }

    func test_aSuccessResetsTheBackoff() {
        let service = OverlayMessagingRequestService(httpClient: UnusedHttpClient())
        _ = service.retryLater()
        _ = service.retryLater()

        service.resetRetry()

        XCTAssertEqual(service.retryLater().nextFetchInSeconds, 60)
    }
}
