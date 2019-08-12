// Copiright 2019 Optimove

import Foundation
import os.log

final class ConfigurationRepository {
    
    enum ConfigurationRepositoryError: Error {
        case noValue
    }
    
    private lazy var accessQueue: DispatchQueue = {
        return DispatchQueue(label: "Configuration repository access queue")
    }()
    
    private var state: OptimoveConfigForExtension?
    
    func obtain() throws -> OptimoveConfigForExtension {
        return try accessQueue.sync {
            guard let state = state else {
                os_log("Obtain no value.", log: OSLog.repository, type: .error)
                throw ConfigurationRepositoryError.noValue
            }
            return state
        }
    }
    
    func update(_ new: OptimoveConfigForExtension) {
        accessQueue.async {
            os_log("Updates value.", log: OSLog.repository, type: .debug)
            self.state = new
        }
    }
}

extension OSLog {
    static let repository = OSLog(subsystem: subsystem, category: "repository")
}
