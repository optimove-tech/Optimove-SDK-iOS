//  Copyright © 2019 Optimove. All rights reserved.

import Foundation

public final class TenantConfigurationDownloader: AsyncOperation {

    private let networking: RemoteConfigurationNetworking
    private let repository: ConfigurationRepository

    public init(networking: RemoteConfigurationNetworking,
         repository: ConfigurationRepository) {
        self.networking = networking
        self.repository = repository
    }

    public override func main() {
        state = .executing
        networking.getTenantConfiguration { (result) in
            do {
                let tenant = try result.get()
                try self.repository.saveTenant(tenant)
            } catch {
//                OptiLoggerMessages.logError(error: error)
            }
            self.state = .finished
        }
    }
}
