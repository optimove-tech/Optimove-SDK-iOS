//  Copyright © 2023 Optimove. All rights reserved.

import OptimoveCore
@testable import OptimoveSDK
import XCTest

final class OptimoveConfigBuilderTests: XCTestCase {
    var optimoveConfigBuilder: OptimoveConfigBuilder!
    override func setUpWithError() throws {
        optimoveConfigBuilder = OptimoveConfigBuilder(region: .DEV, features: [.optimobile, .optimove])
    }

    override func tearDownWithError() throws {
        optimoveConfigBuilder = nil
    }

    func testBuild() throws {
        let config = optimoveConfigBuilder.build()
        XCTAssertNotNil(config)
    }

    func testBuildWithEmptyFeatures() throws {
        optimoveConfigBuilder = OptimoveConfigBuilder(region: .DEV, features: [])
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
            UrlBuilder.Service.push: "https://www.optimove.com",
        ]
        optimoveConfigBuilder.setBaseUrlMapping(baseUrlMap: urlsMap)
        let config = optimoveConfigBuilder.build()
        try UrlBuilder.Service.allCases.forEach { service in
            XCTAssertEqual(try config.optimobileConfig?.urlBuilder.urlForService(service).absoluteString, urlsMap[service]!, "UrlBuilder should return the overridden URL for service \(service)")
        }
    }

    func testBaseUrlMapping() throws {
        try UserDefaults.optimoveAppGroup().set(value: Region.DEV.rawValue, key: .region)
        let urlsMap = UrlBuilder.defaultMapping(for: Region.DEV.rawValue)
        let config = optimoveConfigBuilder.build()
        try UrlBuilder.Service.allCases.forEach { service in
            XCTAssertEqual(try config.optimobileConfig?.urlBuilder.urlForService(service).absoluteString, urlsMap[service]!, "UrlBuilder should return the default URL for service \(service)")
        }
    }
}
