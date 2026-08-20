import XCTest
@testable import OptimoveSDK

final class GamifyWidgetSDKTests: XCTestCase {

    private func runOnMainSync(_ block: @escaping () -> Void) {
        if Thread.isMainThread {
            block()
        } else {
            DispatchQueue.main.sync(execute: block)
        }
    }

    override func setUp() {
        super.setUp()
        runOnMainSync {
            GamifyWidgetSDK.initialize(widgetUrl: "", adactUrl: nil)
        }
    }

    func testInitializeSetsWidgetUrl() {
        let url = "https://gamify-widget.example.com"
        runOnMainSync {
            GamifyWidgetSDK.initialize(widgetUrl: url)
        }
        XCTAssertEqual(GamifyWidgetSDK.widgetUrl, url)
    }

    func testInitializeOverwritesPreviousUrl() {
        runOnMainSync {
            GamifyWidgetSDK.initialize(widgetUrl: "https://first.example.com")
            GamifyWidgetSDK.initialize(widgetUrl: "https://second.example.com")
        }
        XCTAssertEqual(GamifyWidgetSDK.widgetUrl, "https://second.example.com")
    }

    func testInitializeFromBackgroundThreadDispatchesToMain() {
        let url = "https://background.example.com"
        let expectation = expectation(description: "widgetUrl set from background call")
        DispatchQueue.global().async {
            GamifyWidgetSDK.initialize(widgetUrl: url)
            DispatchQueue.main.async {
                XCTAssertEqual(GamifyWidgetSDK.widgetUrl, url)
                expectation.fulfill()
            }
        }
        wait(for: [expectation], timeout: 2.0)
    }

    func testInitializeStoresNormalizedAdactUrl() {
        runOnMainSync {
            GamifyWidgetSDK.initialize(
                widgetUrl: "https://loyalty.example.com",
                adactUrl: "https://campaign.adact.me/"
            )
        }
        XCTAssertEqual(GamifyWidgetSDK.adactUrl, "https://campaign.adact.me")
        XCTAssertEqual(GamifyWidgetSDK.getAdactUrl(), "https://campaign.adact.me/")
    }

    func testGetAdactUrlEmptyWhenNotConfigured() {
        runOnMainSync {
            GamifyWidgetSDK.initialize(widgetUrl: "https://loyalty.example.com")
        }
        XCTAssertEqual(GamifyWidgetSDK.getAdactUrl(), "")
    }

    func testBuildAdactCampaignUrlBuildsEmbeddedPath() {
        runOnMainSync {
            GamifyWidgetSDK.initialize(widgetUrl: "", adactUrl: "https://campaign.adact.me/")
        }
        XCTAssertEqual(
            GamifyWidgetSDK.buildAdactCampaignUrl(params: OpenAdactParams(campaignId: 179)),
            "https://campaign.adact.me/embedded/179"
        )
    }

    func testBuildAdactCampaignUrlAddsCidAndCustomerIdToken() {
        runOnMainSync {
            GamifyWidgetSDK.initialize(widgetUrl: "", adactUrl: "https://campaign.adact.me/")
        }
        let url = GamifyWidgetSDK.buildAdactCampaignUrl(
            params: OpenAdactParams(
                campaignId: 179,
                cid: "customer@example.com",
                token: "jwt-token"
            )
        )
        XCTAssertTrue(url.hasPrefix("https://campaign.adact.me/embedded/179?"))
        XCTAssertTrue(url.contains("cid=customer%40example.com") || url.contains("cid=customer@example.com"))
        XCTAssertTrue(url.contains("customerIdToken=jwt-token"))
    }

    func testBuildAdactCampaignUrlEmptyWhenAdactUrlOrCampaignIdMissing() {
        runOnMainSync {
            GamifyWidgetSDK.initialize(widgetUrl: "https://loyalty.example.com")
        }
        XCTAssertEqual(
            GamifyWidgetSDK.buildAdactCampaignUrl(params: OpenAdactParams(campaignId: 179)),
            ""
        )

        runOnMainSync {
            GamifyWidgetSDK.initialize(widgetUrl: "", adactUrl: "https://campaign.adact.me/")
        }
        XCTAssertEqual(
            GamifyWidgetSDK.buildAdactCampaignUrl(params: OpenAdactParams(cid: "cid")),
            ""
        )
    }

    func testBuildAdactCampaignUrlRejectsNonHttps() {
        runOnMainSync {
            GamifyWidgetSDK.initialize(widgetUrl: "", adactUrl: "http://campaign.adact.me/")
        }
        XCTAssertEqual(
            GamifyWidgetSDK.buildAdactCampaignUrl(params: OpenAdactParams(campaignId: 179)),
            ""
        )
    }
}
