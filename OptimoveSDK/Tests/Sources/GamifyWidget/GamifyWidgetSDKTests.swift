import OptimoveCore
import XCTest
@testable import OptimoveSDK

final class GamifyWidgetSDKTests: XCTestCase {
    private struct TokenError: Error {}

    private let widgetUrl = "https://opti-ls-widget-dev.optimove.net"
    private let tenantId = 593

    private var sdkUserId: String?
    private var authManager: AuthManager?

    override func setUp() {
        super.setUp()
        sdkUserId = nil
        authManager = nil
        GamifyWidgetSDK.resetForTesting(environment: GamifyWidgetSDK.Environment(
            currentUserId: { [unowned self] in self.sdkUserId },
            authManager: { [unowned self] in self.authManager }
        ))
    }

    override func tearDown() {
        GamifyWidgetSDK.resetForTesting()
        super.tearDown()
    }

    private func applyConfig(adactUrl: String? = nil, loyaltyWidgetUrl: String? = nil, tenantId: Int? = nil) {
        GamifyWidgetSDK.applyTenantConfiguration(
            adactUrl: adactUrl,
            loyaltyWidgetUrl: loyaltyWidgetUrl,
            tenantId: tenantId ?? self.tenantId
        )
    }

    private func resolveToken(for userId: String?) -> Result<String?, Error>? {
        let expectation = expectation(description: "token resolved")
        var resolved: Result<String?, Error>?
        let tokenSource = GamifyWidgetSDK.tokenSource(for: userId)
        tokenSource { result in
            resolved = result
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 2.0)
        return resolved
    }

    // MARK: Tenant configuration

    func testApplyTenantConfigurationStoresNormalizedUrls() {
        applyConfig(adactUrl: "https://campaign.adact.me/", loyaltyWidgetUrl: widgetUrl + "/")

        XCTAssertEqual(GamifyWidgetSDK.tenantOptions, GamifyWidgetSDK.TenantOptions(
            adactUrl: "https://campaign.adact.me",
            loyaltyWidgetUrl: widgetUrl,
            tenantId: tenantId
        ))
        XCTAssertEqual(GamifyWidgetSDK.getAdactUrl(), "https://campaign.adact.me/")
    }

    func testApplyTenantConfigurationFromBackgroundThread() {
        let expectation = expectation(description: "applied from background")
        DispatchQueue.global().async {
            self.applyConfig(loyaltyWidgetUrl: self.widgetUrl)
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 2.0)
        XCTAssertEqual(GamifyWidgetSDK.tenantOptions.loyaltyWidgetUrl, widgetUrl)
    }

    func testGetAdactUrlEmptyWhenNotConfigured() {
        applyConfig(loyaltyWidgetUrl: widgetUrl)
        XCTAssertEqual(GamifyWidgetSDK.getAdactUrl(), "")
    }

    // MARK: Loyalty widget URL

    func testBuildLoyaltyWidgetUrl() {
        applyConfig(loyaltyWidgetUrl: widgetUrl + "/")
        XCTAssertEqual(
            GamifyWidgetSDK.buildLoyaltyWidgetUrl(userId: "customer-1", brand: nil),
            "\(widgetUrl)/593/customer-1"
        )
    }

    func testBuildLoyaltyWidgetUrlAddsBrandSegment() {
        applyConfig(loyaltyWidgetUrl: widgetUrl)
        XCTAssertEqual(
            GamifyWidgetSDK.buildLoyaltyWidgetUrl(userId: "customer-1", brand: "brand-a"),
            "\(widgetUrl)/593/brand/brand-a/customer-1"
        )
        XCTAssertEqual(
            GamifyWidgetSDK.buildLoyaltyWidgetUrl(userId: "customer-1", brand: ""),
            "\(widgetUrl)/593/customer-1"
        )
    }

    func testBuildLoyaltyWidgetUrlEncodesPathSegments() {
        applyConfig(loyaltyWidgetUrl: widgetUrl)
        XCTAssertEqual(
            GamifyWidgetSDK.buildLoyaltyWidgetUrl(userId: "a/b c", brand: "x/y"),
            "\(widgetUrl)/593/brand/x%2Fy/a%2Fb%20c"
        )
    }

    func testBuildLoyaltyWidgetUrlEmptyWhenInputsMissing() {
        XCTAssertEqual(GamifyWidgetSDK.buildLoyaltyWidgetUrl(userId: "customer-1", brand: nil), "")

        applyConfig(loyaltyWidgetUrl: widgetUrl)
        XCTAssertEqual(GamifyWidgetSDK.buildLoyaltyWidgetUrl(userId: nil, brand: nil), "")
        XCTAssertEqual(GamifyWidgetSDK.buildLoyaltyWidgetUrl(userId: "", brand: nil), "")

        applyConfig(loyaltyWidgetUrl: widgetUrl, tenantId: -1)
        XCTAssertEqual(GamifyWidgetSDK.buildLoyaltyWidgetUrl(userId: "customer-1", brand: nil), "")
    }

    func testBuildLoyaltyWidgetUrlRejectsNonHttps() {
        applyConfig(loyaltyWidgetUrl: "http://opti-ls-widget-dev.optimove.net")
        XCTAssertEqual(GamifyWidgetSDK.buildLoyaltyWidgetUrl(userId: "customer-1", brand: nil), "")
    }

    // MARK: Auth token

    func testTokenSourceMintsJwtForGivenUser() {
        var requestedFor: [String] = []
        authManager = AuthManager { userId, completion in
            requestedFor.append(userId)
            completion("jwt-token", nil)
        }

        guard case let .success(token) = resolveToken(for: "customer-1") else {
            return XCTFail("Expected a token")
        }
        XCTAssertEqual(token, "jwt-token")
        XCTAssertEqual(requestedFor, ["customer-1"])
    }

    func testTokenSourceResolvesNilWhenAuthNotEnabled() {
        guard case let .success(token) = resolveToken(for: "customer-1") else {
            return XCTFail("Expected success without a token")
        }
        XCTAssertNil(token)
    }

    func testTokenSourceFailsWhenTokenCannotBeMinted() {
        authManager = AuthManager { _, completion in completion(nil, TokenError()) }

        guard case .failure = resolveToken(for: "customer-1") else {
            return XCTFail("Expected failure")
        }
    }

    // MARK: Adact

    func testBuildAdactCampaignUrlBuildsEmbeddedPath() {
        applyConfig(adactUrl: "https://campaign.adact.me/")
        XCTAssertEqual(
            GamifyWidgetSDK.buildAdactCampaignUrl(params: OpenAdactParams(campaignId: 179)),
            "https://campaign.adact.me/embedded/179"
        )
    }

    func testBuildAdactCampaignUrlAddsCidAndCustomerIdToken() {
        applyConfig(adactUrl: "https://campaign.adact.me/")
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
        applyConfig(loyaltyWidgetUrl: widgetUrl)
        XCTAssertEqual(
            GamifyWidgetSDK.buildAdactCampaignUrl(params: OpenAdactParams(campaignId: 179)),
            ""
        )

        applyConfig(adactUrl: "https://campaign.adact.me/")
        XCTAssertEqual(
            GamifyWidgetSDK.buildAdactCampaignUrl(params: OpenAdactParams(cid: "cid")),
            ""
        )
    }

    func testBuildAdactCampaignUrlRejectsNonHttps() {
        applyConfig(adactUrl: "http://campaign.adact.me/")
        XCTAssertEqual(
            GamifyWidgetSDK.buildAdactCampaignUrl(params: OpenAdactParams(campaignId: 179)),
            ""
        )
    }
}
