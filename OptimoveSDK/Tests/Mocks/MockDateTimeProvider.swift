// Copiright 2019 Optimove

import Foundation
@testable import OptimoveSDK

final class MockDateTimeProvider {
    var mockedNow: Date = Date()
}

extension MockDateTimeProvider: DateTimeProvider {
    var now: Date {
        return mockedNow
    }
}
