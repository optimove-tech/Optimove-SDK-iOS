//  Copyright © 2019 Optimove. All rights reserved.

@testable import OptimoveCore
import XCTest
import OptimoveTest

class ConfigurationBuilderTests: XCTestCase {
    func test_build_configuration() {
        let tenantConfig = TenantConfigFixture().build()
        let globalConfig = GlobalConfigFixture().build()

        let builder = ConfigurationBuilder(globalConfig: globalConfig, tenantConfig: tenantConfig)
        let configuration = builder.build()

        XCTAssert(configuration.tenantID == tenantConfig.optitrack.siteId)
        XCTAssert(configuration.logger.logServiceEndpoint == globalConfig.general.logsServiceEndpoint)
        XCTAssert(configuration.optitrack.eventCategoryName == globalConfig.optitrack.eventCategoryName)
    }
}
