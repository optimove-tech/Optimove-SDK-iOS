import XCTest
@testable import OptimoveSDK

final class GamifyWidgetSDKTests: XCTestCase {

    override func setUp() {
        super.setUp()
        GamifyWidgetSDK.initialize(widgetUrl: "")
    }

    func testInitializeSetsWidgetUrl() {
        let url = "https://gamify-widget.example.com"
        GamifyWidgetSDK.initialize(widgetUrl: url)
        XCTAssertEqual(GamifyWidgetSDK.widgetUrl, url)
    }

    func testInitializeOverwritesPreviousUrl() {
        GamifyWidgetSDK.initialize(widgetUrl: "https://first.example.com")
        GamifyWidgetSDK.initialize(widgetUrl: "https://second.example.com")
        XCTAssertEqual(GamifyWidgetSDK.widgetUrl, "https://second.example.com")
    }
}
