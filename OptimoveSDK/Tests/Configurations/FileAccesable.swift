//  Copyright © 2019 Optimove. All rights reserved.

import Foundation

/// Helps to fetch JSON files.
protocol FileAccesable: class {
    /// The name of the json name.
    var fileName: String { get }
    /// Returns Data from JSON file if exists.
    var data: Data { get }
}

extension FileAccesable {

    var data: Data {
        let bundle = Bundle(for: type(of: self))
        let url = bundle.url(forResource: fileName, withExtension: "")!
        return try! Data(contentsOf: url)
    }

}
