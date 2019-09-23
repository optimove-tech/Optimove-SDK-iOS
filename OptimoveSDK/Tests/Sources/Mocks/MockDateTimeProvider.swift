//  Copyright © 2019 Optimove. All rights reserved.

import Foundation
@testable import OptimoveSDK

final class MockDateTimeProvider {
    var mockedNow = Date()
}

extension MockDateTimeProvider: DateTimeProvider {
    var now: Date {
        return mockedNow
    }
}
