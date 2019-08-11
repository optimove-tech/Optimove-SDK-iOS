// Copiright 2019 Optimove

import Foundation
import os.log

final class ConfigurationFetcher: AsyncOperation {
    
    private let tenantInfo: NotificationExtensionTenantInfo
    private let repository: ConfigurationRepository
    private let bundleIdentifier: String
    
    init(tenantInfo: NotificationExtensionTenantInfo,
         repository: ConfigurationRepository,
         bundleIdentifier: String) {
        self.tenantInfo = tenantInfo
        self.repository = repository
        self.bundleIdentifier = bundleIdentifier
    }
    
    override func main() {
        state = .executing
        
        handleFetchConfigFromRemoteEndpoint(tenantInfo: tenantInfo) { [unowned self] (result) in
            switch result {
            case let .failure(error):
                os_log("Error: %{PRIVATE}@", log: OSLog.fetcher, type: .error, error.localizedDescription)
                self.handleFetchConfigFromLocalFileSystem(completion: { (result) in
                    switch result {
                    case let .success(configurations):
                        self.repository.update(configurations)
                    case let .failure(error):
                        os_log("Error: %{PRIVATE}@", log: OSLog.fetcher, type: .error, error.localizedDescription)
                    }
                    self.state = .finished
                })
            case let .success(configurations):
                self.repository.update(configurations)
                self.state = .finished
            }
        }
        
    }
}

private extension ConfigurationFetcher {
    
    enum ConfigurationFetcherError: LocalizedError {
        case wrongURL(tenant: NotificationExtensionTenantInfo)
        case networkIssue(error: Error)
        case noData
        case failedToParse(error: Error)
        case fileNotExists
        
        var localizedDescription: String {
            switch self {
            case let .wrongURL(tenant: tenantInfo):
                return """
                Can not initialize an URL to fetch tenant's config. Variables:
                - endpoint: \(tenantInfo.endpoint)
                - token: \(tenantInfo.token)
                - version: \(tenantInfo.version)
                """
            case let .networkIssue(error: error):
                return "Configuration fetched from network failed with error: \(error.localizedDescription)"
            case .noData:
                return "Configuration fetched from network do not contain any data"
            case let .failedToParse(error: error):
                return "Failed to parse configuration file with error: \(error.localizedDescription)"
            case .fileNotExists:
                return "The local config file is not exist."
            }
        }
    }
    
    func handleFetchConfigFromRemoteEndpoint(
        tenantInfo: NotificationExtensionTenantInfo,
        completion: @escaping (Result<OptimoveConfigForExtension, ConfigurationFetcherError>) -> Void
        ) {
        let urlString = "\(tenantInfo.endpoint)\(tenantInfo.token)/\(tenantInfo.version).json"
        guard let configsUrl = URL(string: urlString) else {
            completion(.failure(.wrongURL(tenant: tenantInfo)))
            return
        }
        let task = URLSession.shared.dataTask(with: configsUrl) { (data, reponse, error) in
            if let error = error {
                completion(.failure(.networkIssue(error: error)))
                return
            }
            guard let data = data else {
                completion(.failure(.noData))
                return
            }
            do {
                let decoder = JSONDecoder()
                let config = try decoder.decode(OptimoveConfigForExtension.self, from: data)
                os_log("Remote configs parsed successfully.", log: OSLog.fetcher, type: .info)
                completion(.success(config))
            } catch {
                completion(.failure(.failedToParse(error: error)))
            }
        }
        task.resume()
    }
    
    func handleFetchConfigFromLocalFileSystem(
        completion: @escaping (Result<OptimoveConfigForExtension, ConfigurationFetcherError>) -> Void
    ) {
        os_log("Attempt to fetch a local configs.", log: OSLog.fetcher, type: .debug)
        let fileManager = FileManager.default
        let containerAppllicationUrl = fileManager.containerURL(
            forSecurityApplicationGroupIdentifier: "group.\(bundleIdentifier).optimove"
        )
        do {
            let urls = try fileManager.url(for: .applicationSupportDirectory,
                                           in: .userDomainMask,
                                           appropriateFor: containerAppllicationUrl,
                                           create: true)
            let optimovePath = urls.appendingPathComponent("OptimoveSDK")
            let fileUrl = optimovePath.appendingPathComponent("\(self.tenantInfo.version).json")
            guard FileManager.default.fileExists(atPath: fileUrl.path) else {
                completion(.failure(.fileNotExists))
                return
            }
            let data = try Data(contentsOf: fileUrl)
            let optimoveConfigs = try JSONDecoder().decode(OptimoveConfigForExtension.self, from: data)
            os_log("Local configs successfully parsed", log: OSLog.fetcher, type: .debug)
            completion(.success(optimoveConfigs))
        } catch {
            completion(.failure(.failedToParse(error: error)))
        }
    }
    
    
}

extension OSLog {
    static let fetcher = OSLog(subsystem: subsystem, category: "fetcher")
}
