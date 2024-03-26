//  Copyright © 2023 Optimove. All rights reserved.

struct OptimobileCredentials: Codable {
    let apiKey: String
    let secretKey: String

    init(apiKey: String, secretKey: String) {
        self.apiKey = apiKey
        self.secretKey = secretKey
    }
}
