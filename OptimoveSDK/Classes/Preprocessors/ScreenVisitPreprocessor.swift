//  Copyright © 2019 Optimove. All rights reserved.

import Foundation

struct ScreenVisitPreprocessor {

    struct Constants {
        static let suffix = "/"
    }

    enum Error: Swift.Error {
        case leftEmptyStringAfterEncoding
    }

    static func process(_ input: String) throws -> String {
        let input = processPrefix(input).lowercased().addingPercentEncoding(withAllowedCharacters: .urlPathAllowed)
        guard input != nil else {
            throw Error.leftEmptyStringAfterEncoding
        }
        let result = processSuffixes(input!)
        let appNameSpace = try Bundle.getApplicationNameSpace()
        return "\(appNameSpace)/\(result)".lowercased()
    }
}

private extension ScreenVisitPreprocessor {

    static func processPrefix(_ input: String) -> String {
        var input = input
        if input.hasPrefix(Constants.suffix) {
            input.removeFirst(Constants.suffix.count)
        }
        return removeUrlProtocol(input)
    }

    static func removeUrlProtocol(_ input: String) -> String {
        var input = input
        for prefix in ["https://www.", "http://www.", "https://", "http://"] {
            if input.hasPrefix(prefix) {
                input.removeFirst(prefix.count)
            }
        }
        return input
    }

    static func processSuffixes(_ input: String) -> String {
        var input = input
        if input.hasSuffix(Constants.suffix) {
            input.append(Constants.suffix)
        }
        return input
    }
}
