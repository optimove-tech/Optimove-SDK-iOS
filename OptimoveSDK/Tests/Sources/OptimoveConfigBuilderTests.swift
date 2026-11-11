//  Copyright © 2023 Optimove. All rights reserved.

@testable import OptimoveSDK
import XCTest

final class OptimoveConfigBuilderTests: XCTestCase {
    var optimoveConfigBuilder: OptimoveConfigBuilder!
    override func setUpWithError() throws {
        optimoveConfigBuilder = OptimoveConfigBuilder(features: [.optimobile, .optimove])
    }

    override func tearDownWithError() throws {
        optimoveConfigBuilder = nil
    }

    func testBuild() throws {
        let config = optimoveConfigBuilder.build()
        XCTAssertNotNil(config)
    }

    func testBuildWithEmptyFeatures() throws {
        optimoveConfigBuilder = OptimoveConfigBuilder(features: [])
        let config = optimoveConfigBuilder.build()
        XCTAssertTrue(config.features.contains(.delayedConfiguration), "delayedConfiguration feature should be enabled if no features are passed")
    }

    func testOverrideBaseUrlMapping() throws {
        let urlsMap = [
            UrlBuilder.Service.crm: "https://www.optimove.com",
            UrlBuilder.Service.ddl: "https://www.optimove.com",
            UrlBuilder.Service.events: "https://www.optimove.com",
            UrlBuilder.Service.iar: "https://www.optimove.com",
            UrlBuilder.Service.media: "https://www.optimove.com",
            UrlBuilder.Service.overlayMessaging: "https://www.optimove.com",
            UrlBuilder.Service.push: "https://www.optimove.com",
        ]
        optimoveConfigBuilder.setBaseUrlMapping(baseUrlMap: urlsMap)
        let config = optimoveConfigBuilder.build()
        try UrlBuilder.Service.allCases.forEach { service in
            XCTAssertEqual(try config.optimobileConfig?.urlBuilder.urlForService(service).absoluteString, urlsMap[service]!, "UrlBuilder should return the overridden URL for service \(service)")
        }
    }

    func testBaseUrlMapping() throws {
        KeyValPersistenceHelper.set(Region.DEV.rawValue, forKey: OptimobileUserDefaultsKey.REGION.rawValue)
        let urlsMap = UrlBuilder.defaultMapping(for: Region.DEV.rawValue)
        let config = optimoveConfigBuilder.build()
        try UrlBuilder.Service.allCases.forEach { service in
            XCTAssertEqual(try config.optimobileConfig?.urlBuilder.urlForService(service).absoluteString, urlsMap[service]!, "UrlBuilder should return the default URL for service \(service)")
        }
    }
    // MARK: - Overlay messaging

    func testOverlayMessagingIsOffByDefault() throws {
        let config = optimoveConfigBuilder.build().optimobileConfig

        XCTAssertEqual(config?.isOverlayMessagingEnabled, false)
    }

    func testOverlayMessagingDefaultsToAOneHourSessionAndAOneHourDeferDelay() throws {
        let config = optimoveConfigBuilder.enableOverlayMessaging().build().optimobileConfig

        XCTAssertEqual(config?.isOverlayMessagingEnabled, true)
        XCTAssertEqual(config?.overlayMessagingSessionLengthMinutes, 60)
        XCTAssertEqual(config?.overlayMessagingDeferDelayMinutes, 60)
    }

    func testOverlayMessagingSessionLengthInHours() throws {
        let config = optimoveConfigBuilder.enableOverlayMessaging(sessionLengthHours: 3).build().optimobileConfig

        XCTAssertEqual(config?.overlayMessagingSessionLengthMinutes, 180)
    }

    func testOverlayMessagingSessionLengthCanBe0() throws {
        let hours = OptimoveConfigBuilder(features: [.optimobile]).enableOverlayMessaging(sessionLengthHours: 0).build()
        let minutes = OptimoveConfigBuilder(features: [.optimobile]).enableOverlayMessaging(sessionLengthMinutes: 0).build()

        XCTAssertEqual(hours.optimobileConfig?.overlayMessagingSessionLengthMinutes, 0)
        XCTAssertEqual(minutes.optimobileConfig?.overlayMessagingSessionLengthMinutes, 0)
    }

    func testOverlayMessagingSessionLengthUnder15Minutes() throws {
        let config = optimoveConfigBuilder.enableOverlayMessaging(sessionLengthMinutes: 5).build().optimobileConfig

        XCTAssertEqual(config?.overlayMessagingSessionLengthMinutes, 5)
    }

    func testOverlayMessagingDeferDelay() throws {
        let hours = OptimoveConfigBuilder(features: [.optimobile]).enableOverlayMessaging(sessionLengthHours: 1, deferDelayMinutes: 1).build()
        let minutes = OptimoveConfigBuilder(features: [.optimobile]).enableOverlayMessaging(sessionLengthMinutes: 30, deferDelayMinutes: 90).build()

        XCTAssertEqual(hours.optimobileConfig?.overlayMessagingDeferDelayMinutes, 1)
        XCTAssertEqual(minutes.optimobileConfig?.overlayMessagingDeferDelayMinutes, 90)
    }
}
