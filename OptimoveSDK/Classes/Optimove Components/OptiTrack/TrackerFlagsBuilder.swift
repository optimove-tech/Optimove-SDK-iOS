//  Copyright © 2019 Optimove. All rights reserved.

import Foundation
import OptimoveCore

final class TrackerFlagsBuilder {

    private let storage: OptimoveStorage
    private let pluginFlags = ["fla", "java", "dir", "qt", "realp", "pdf", "wma", "gears"]
    private let splitter: Int = 2

    init(storage: OptimoveStorage) {
        self.storage = storage
    }

    func build() throws -> [String: String] {
        let idx = try storage.getInitialVisitorId().alphanumeric
        guard !idx.isBlank else {
            throw TrackerFlagsBuilderError.blankInitialVisitorID
        }
        guard idx.count > splitter else {
            throw TrackerFlagsBuilderError.spliterMoreThanLenghtOfInitialVisitorID(lenght: splitter)
        }
        let pluginValues = try idx.split(by: splitter)
            .map {
                try unwrap(Int($0, radix: 16)) / 2
            }
            .map { $0.description }
        return zip(pluginFlags, pluginValues).reduce(into: [String: String](), { (result, next) in
            result[next.0] = next.1
        })
    }

}

enum TrackerFlagsBuilderError: LocalizedError {
    case blankInitialVisitorID
    case spliterMoreThanLenghtOfInitialVisitorID(lenght: Int)

    var errorDescription: String {
        switch self {
        case .blankInitialVisitorID:
            return "Unable to build tracker flags. Reason: Required InitialVisitorID value is blank"
        case let .spliterMoreThanLenghtOfInitialVisitorID(lenght: lenght):
            return "Unable to build tracker flags. Reason: Required InitialVisitorID cannot be splitted by \(lenght)"
        }
    }
}
