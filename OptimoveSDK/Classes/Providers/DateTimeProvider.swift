// Copiright 2019 Optimove

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
