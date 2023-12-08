//  Copyright © 2023 Optimove. All rights reserved.

import Foundation

public struct OptimobileCredentials: Codable {
    public let apiKey: String
    public let secretKey: String

    public init(apiKey: String, secretKey: String) {
        self.apiKey = apiKey
        self.secretKey = secretKey
    }
}
