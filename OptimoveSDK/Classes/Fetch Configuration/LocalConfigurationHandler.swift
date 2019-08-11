import Foundation

final class LocalConfigurationHandler {

    private let storage: OptimoveStorage

    init(storage: OptimoveStorage) {
        self.storage = storage
    }

    func get(completionHandler: @escaping ResultBlockWithData) {
        guard let fileName = storage.version else { return }
        let configFileName = fileName + ".json"

        if let configData = try? storage.load(fileName: configFileName, shared: true) {
            completionHandler(configData, nil)
        } else {
            completionHandler(nil, .emptyData)
        }
    }
}
