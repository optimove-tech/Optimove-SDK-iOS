//  Copyright © 2019 Optimove. All rights reserved.

import Foundation

/// Helps to fetch JSON files.
protocol FileAccessible: class {
    /// The name of the json name.
    var fileName: String { get }
    /// Returns Data from JSON file if exists.
    var data: Data { get }
}

extension FileAccessible {

    var data: Data {
        let bundle = Bundle(for: type(of: self))
        guard let url = bundle.url(forResource: fileName, withExtension: "") else {
            fatalError("File name: \(fileName) does not exist.")
        }
        guard let data = try? Data(contentsOf: url) else {
            fatalError("Unable to fetch data from file: \(fileName).")
        }
        return data
    }

}
