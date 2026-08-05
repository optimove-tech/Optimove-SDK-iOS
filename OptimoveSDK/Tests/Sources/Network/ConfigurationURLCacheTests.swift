//  Copyright © 2026 Optimove. All rights reserved.

import XCTest
@testable import OptimoveSDK

final class ConfigurationURLCacheTests: XCTestCase {

    // URLSession's automatic caching refuses to store a response larger than roughly
    // 5% of the cache capacity. Measured against a local server: a 944 KB response is
    // not stored in a 10 MB cache and is stored in a 20 MB one. The capacity therefore
    // has to be at least 20x the largest configuration we expect, or the response is
    // silently never cached, no validator is kept, and the whole file is refetched on
    // every launch.
    private let expectedMaxConfigurationSize = 1 << 20 // 1 MB

    func test_configurationCache_canHoldTheLargestExpectedConfiguration() {
        XCTAssertGreaterThanOrEqual(
            ServiceLocator.configurationURLCache.diskCapacity,
            expectedMaxConfigurationSize * 20,
            "URLSession would refuse to store the tenant configuration in a cache this small"
        )
    }

    func test_configurationCache_isNotTheSharedCache() {
        XCTAssertFalse(
            ServiceLocator.configurationURLCache === URLCache.shared,
            "Configuration networking must not use the host app's shared cache"
        )
    }
}
