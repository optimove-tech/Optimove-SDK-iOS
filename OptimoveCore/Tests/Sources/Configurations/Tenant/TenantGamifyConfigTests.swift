//  Copyright © 2026 Optimove. All rights reserved.

@testable import OptimoveCore
import OptimoveTest
import XCTest

class TenantGamifyConfigTests: XCTestCase {
    private func tenantJson(gamify: String?) -> Data {
        let gamifyEntry = gamify.map { ", \"gamify\": \($0)" } ?? ""
        return """
        {
            "enableRealtime": false,
            "realtimeMetaData": { "realtimeGateway": "https://realtime.example.com/" },
            "optitrackMetaData": { "optitrackEndpoint": "https://optitrack.example.com/", "siteId": 593 },
            "events": {}\(gamifyEntry)
        }
        """.data(using: .utf8)!
    }

    func test_gamify_is_nil_when_absent_from_tenant_config() throws {
        let config = try JSONDecoder().decode(TenantConfig.self, from: tenantJson(gamify: nil))

        XCTAssertNil(config.gamify)
    }

    func test_gamify_fields_are_decoded() throws {
        let json = tenantJson(gamify: """
        { "adactUrl": "https://adact-campaign-dev.optimove.net/", "loyaltyWidgetUrl": "https://opti-ls-widget-dev.optimove.net/" }
        """)
        let config = try JSONDecoder().decode(TenantConfig.self, from: json)

        XCTAssertEqual(config.gamify?.adactUrl, "https://adact-campaign-dev.optimove.net/")
        XCTAssertEqual(config.gamify?.loyaltyWidgetUrl, "https://opti-ls-widget-dev.optimove.net/")
    }

    func test_each_gamify_field_is_independently_optional() throws {
        let json = tenantJson(gamify: """
        { "loyaltyWidgetUrl": "https://opti-ls-widget-dev.optimove.net/" }
        """)
        let config = try JSONDecoder().decode(TenantConfig.self, from: json)

        XCTAssertNil(config.gamify?.adactUrl)
        XCTAssertEqual(config.gamify?.loyaltyWidgetUrl, "https://opti-ls-widget-dev.optimove.net/")
    }

    func test_gamify_survives_encode_decode() throws {
        let json = tenantJson(gamify: """
        { "adactUrl": "https://adact.example.com", "loyaltyWidgetUrl": "https://widget.example.com" }
        """)
        let config = try JSONDecoder().decode(TenantConfig.self, from: json)
        let decoded = try JSONDecoder().decode(TenantConfig.self, from: JSONEncoder().encode(config))

        XCTAssertEqual(decoded.gamify, config.gamify)
    }

    func test_configuration_builder_carries_gamify() {
        let fixture = TenantConfigFixture()
        let base = fixture.build()
        let gamify = TenantGamifyConfig(adactUrl: "https://adact.example.com", loyaltyWidgetUrl: "https://widget.example.com")
        let tenantConfig = TenantConfig(
            realtime: base.realtime,
            optitrack: base.optitrack,
            events: base.events,
            isEnableRealtime: base.isEnableRealtime,
            isSupportedAirship: base.isSupportedAirship,
            isEnableRealtimeThroughOptistream: base.isEnableRealtimeThroughOptistream,
            isProductionLogsEnabled: base.isProductionLogsEnabled,
            gamify: gamify
        )

        let configuration = ConfigurationBuilder(globalConfig: GlobalConfigFixture().build(), tenantConfig: tenantConfig).build()

        XCTAssertEqual(configuration.gamify, gamify)
    }
}
