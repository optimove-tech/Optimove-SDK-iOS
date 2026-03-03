import XCTest
@testable import OptimoveSDK

final class UrlBuilderDelayedInitTests: XCTestCase {

    override func setUp() {
        super.setUp()
        KeyValPersistenceHelper.removeObject(forKey: OptimobileUserDefaultsKey.REGION.rawValue)
        KeyValPersistenceHelper.removeObject(forKey: OptimobileUserDefaultsKey.MEDIA_BASE_URL.rawValue)
    }

    override func tearDown() {
        KeyValPersistenceHelper.removeObject(forKey: OptimobileUserDefaultsKey.REGION.rawValue)
        KeyValPersistenceHelper.removeObject(forKey: OptimobileUserDefaultsKey.MEDIA_BASE_URL.rawValue)
        super.tearDown()
    }

    // MARK: - UrlBuilder.region

    func test_urlBuilder_region_throws_when_not_in_storage() {
        let urlBuilder = UrlBuilder(storage: KeyValPersistenceHelper.self)
        XCTAssertThrowsError(try urlBuilder.region) { error in
            guard case UrlBuilder.Error.regionNotSet = error else {
                return XCTFail("Expected UrlBuilder.Error.regionNotSet, got \(error)")
            }
        }
    }

    func test_urlBuilder_region_returns_value_when_in_storage() throws {
        KeyValPersistenceHelper.set(Region.EU.rawValue, forKey: OptimobileUserDefaultsKey.REGION.rawValue)
        let urlBuilder = UrlBuilder(storage: KeyValPersistenceHelper.self)
        let region = try urlBuilder.region
        XCTAssertEqual(region, Region.EU.rawValue)
    }

    func test_urlBuilder_urlForService_throws_when_region_not_set() {
        let urlBuilder = UrlBuilder(storage: KeyValPersistenceHelper.self)
        XCTAssertThrowsError(try urlBuilder.urlForService(.events)) { error in
            guard case UrlBuilder.Error.regionNotSet = error else {
                return XCTFail("Expected UrlBuilder.Error.regionNotSet, got \(error)")
            }
        }
    }

    func test_urlBuilder_urlForService_succeeds_when_region_set() throws {
        KeyValPersistenceHelper.set(Region.EU.rawValue, forKey: OptimobileUserDefaultsKey.REGION.rawValue)
        let urlBuilder = UrlBuilder(storage: KeyValPersistenceHelper.self)
        let url = try urlBuilder.urlForService(.events)
        XCTAssertTrue(url.absoluteString.contains(Region.EU.rawValue))
    }

    func test_urlBuilder_runtimeUrlsMap_bypasses_region() throws {
        let urlBuilder = UrlBuilder(storage: KeyValPersistenceHelper.self)
        urlBuilder.runtimeUrlsMap = [
            .crm: "https://crm.test",
            .ddl: "https://ddl.test",
            .events: "https://events.test",
            .iar: "https://iar.test",
            .media: "https://media.test",
            .push: "https://push.test",
        ]
        let url = try urlBuilder.urlForService(.events)
        XCTAssertEqual(url.absoluteString, "https://events.test")
    }

    // MARK: - updateStorageValues

    func test_updateStorageValues_noops_when_region_nil() {
        let config = buildOptimobileConfig(region: nil)!
        Optimobile.updateStorageValues(config)

        XCTAssertNil(KeyValPersistenceHelper.object(forKey: OptimobileUserDefaultsKey.REGION.rawValue))
        XCTAssertNil(KeyValPersistenceHelper.object(forKey: OptimobileUserDefaultsKey.MEDIA_BASE_URL.rawValue))
    }

    func test_updateStorageValues_writes_region_and_media_url() {
        let config = buildOptimobileConfig(region: .EU)!
        Optimobile.updateStorageValues(config)

        let storedRegion = KeyValPersistenceHelper.object(forKey: OptimobileUserDefaultsKey.REGION.rawValue) as? String
        let storedMediaUrl = KeyValPersistenceHelper.object(forKey: OptimobileUserDefaultsKey.MEDIA_BASE_URL.rawValue) as? String

        XCTAssertEqual(storedRegion, Region.EU.rawValue)
        XCTAssertEqual(storedMediaUrl, "https://i-\(Region.EU.rawValue).app.delivery")
    }

    func test_updateStorageValues_makes_urlBuilder_resolve() throws {
        let config = buildOptimobileConfig(region: .US)!
        Optimobile.updateStorageValues(config)

        let urlBuilder = UrlBuilder(storage: KeyValPersistenceHelper.self)
        let region = try urlBuilder.region
        XCTAssertEqual(region, Region.US.rawValue)

        let eventsUrl = try urlBuilder.urlForService(.events)
        XCTAssertTrue(eventsUrl.absoluteString.contains(Region.US.rawValue))
    }

    // MARK: - Helpers

    private func buildOptimobileConfig(region: Region?) -> OptimobileConfig? {
        let builder = OptimoveConfigBuilder(features: [.optimobile])
        builder.region = region
        return builder.build().optimobileConfig
    }
}
