// Copiright 2019 Optimove

import Foundation
@testable import OptimoveSDK

final class MockStatisticService: StatisticService {
    var applicationOpenTime: TimeInterval = Date().timeIntervalSinceNow
}
