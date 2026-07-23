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
            GamifyWidgetSDK.initialize(widgetUrl: "")
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
}
