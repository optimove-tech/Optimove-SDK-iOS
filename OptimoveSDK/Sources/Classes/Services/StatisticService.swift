//  Copyright © 2019 Optimove. All rights reserved.

import Foundation

protocol StatisticService {
    var applicationOpenTime: TimeInterval { get set }
}

final class StatisticServiceImpl {
    private var _applicationOpenTime: TimeInterval = Date().timeIntervalSince1970
}

extension StatisticServiceImpl: StatisticService {
    var applicationOpenTime: TimeInterval {
        get {
            return _applicationOpenTime
        }
        set {
            _applicationOpenTime = newValue
        }
    }
}
