//  Copyright © 2019 Optimove. All rights reserved.

import Foundation
@testable import OptimoveSDK

final class MockStatisticService: StatisticService {
    var applicationOpenTime: TimeInterval = Date().timeIntervalSinceNow
}
