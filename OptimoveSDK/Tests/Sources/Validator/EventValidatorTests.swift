//  Copyright © 2020 Optimove. All rights reserved.

import XCTest
import OptimoveCore
@testable import OptimoveSDK

class EventValidatorTests: OptimoveTestCase {

    var validator: EventValidator!

    override func setUpWithError() throws {
        let builder = ConfigurationBuilder(
            globalConfig: GlobalConfigFixture().build(),
            tenantConfig: TenantConfigFixture().build()
        )
        validator = EventValidator(configuration: builder.build())
    }

    func test_support_nondefined_parameters() throws {
        let event = StubEvent(context: [
            "nondefined_key": "nondefined_value"
        ])
        XCTAssertNoThrow( try validator.execute(.report(events: [event])))
    }

    func test_undefinedName_error() {
        try validator.execute(.report(events: [event]))
    }

}
