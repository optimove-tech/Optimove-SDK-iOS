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
}
