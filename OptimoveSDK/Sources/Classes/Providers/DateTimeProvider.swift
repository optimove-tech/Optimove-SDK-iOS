//  Copyright © 2019 Optimove. All rights reserved.

import Foundation

/// Use for mocking date and time.
protocol DateTimeProvider {
    var now: Date { get }
}

final class DateTimeProviderImpl { }

extension DateTimeProviderImpl: DateTimeProvider {

    var now: Date {
        return Date()
    }

}
