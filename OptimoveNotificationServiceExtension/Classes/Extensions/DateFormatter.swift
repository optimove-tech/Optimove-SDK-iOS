//  Copyright © 2019 Optimove. All rights reserved.

import Foundation

extension DateFormatter {
    static let hourDateFormatter: DateFormatter = {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "HH"
        return dateFormatter
    }()

    static let minuteDateFormatter: DateFormatter = {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "mm"
        return dateFormatter
    }()

    static let secondsDateFormatter: DateFormatter = {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "ss"
        return dateFormatter
    }()
    static let iso8601DateFormatter: DateFormatterProtocol = {
        return ISO8601DateFormatter()
    }()
}

protocol DateFormatterProtocol {
    func string(from date: Date) -> String
    func date(from string: String) -> Date?
}

extension ISO8601DateFormatter: DateFormatterProtocol {}
