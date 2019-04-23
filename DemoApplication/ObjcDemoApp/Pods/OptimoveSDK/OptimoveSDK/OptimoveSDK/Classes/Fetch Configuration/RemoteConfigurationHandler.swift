import Foundation

class RemoteConfigurationHandler {

    func get(completionHandler: @escaping ResultBlockWithData) {
        self.downloadConfigurations { (data, error) in
            completionHandler(data, error)
        }
    }

    private func downloadConfigurations(didComplete: @escaping ResultBlockWithData) {
        if let tenantToken = OptimoveUserDefaults.shared.tenantToken, let version = Version {
            // configuration end point always ends with '/'
            let path = "\(OptimoveUserDefaults.shared.configurationEndPoint)\(tenantToken)/\(version).json"

            OptiLoggerMessages.logPathToRemoteConfiguration(path: path)

            if let url = URL(string: path) {
                NetworkManager.get(from: url) {
                    (response, error)  in
                    didComplete(response, error)
                }
            }
        }
    }
}
