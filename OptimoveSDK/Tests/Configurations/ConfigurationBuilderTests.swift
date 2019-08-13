//  Copyright © 2019 Optimove. All rights reserved.

import XCTest
@testable import OptimoveSDK

class ConfigurationBuilderTests: XCTestCase {

    func test_build_configuration() {
        let tenantConfig = tenantConfigFixture()
        let globalConfig = globalConfigFixture()

        let builder = ConfigurationBuilder(globalConfig: globalConfig, tenantConfig: tenantConfig)
        let configuration = builder.build()

        XCTAssert(configuration.tenantID == tenantConfig.optitrack.siteId)
        XCTAssert(configuration.logger.logServiceEndpoint == globalConfig.general.logsServiceEndpoint)
        XCTAssert(configuration.realtime.realtimeToken == tenantConfig.realtime.realtimeToken)
        XCTAssert(configuration.optipush.registrationServiceEndpoint == globalConfig.optipush.registrationServiceEndpoint)
        XCTAssert(configuration.optitrack.eventCategoryName == globalConfig.optitrack.eventCategoryName)
    }

    // TODO: Improve a configuration creation coverage.

}
