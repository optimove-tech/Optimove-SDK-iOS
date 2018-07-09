

import Foundation

class LocalConfigurationHandler {
    func get(completionHandler: @escaping ResultBlockWithData) {
        
        guard let fileName = OptimoveUserDefaults.shared.version else {return}
        
        let configFileName =  fileName + ".json"
        
        if let configData  = OptimoveFileManager.load(file: configFileName) {
            completionHandler(configData,nil)
        } else {
            completionHandler(nil,.emptyData)
        }
    }
}
