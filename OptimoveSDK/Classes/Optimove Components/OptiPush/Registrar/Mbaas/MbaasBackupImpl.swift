// Copiright 2019 Optimove

import Foundation

protocol MbaasBackup {
    func backup<T: BaseMbaasModel>(_ model: T) throws
    func clearLast(for operation: MbaasOperation) throws
    func restoreLast<T: BaseMbaasModel>(for operation: MbaasOperation) throws -> T
}

final class MbaasBackupImpl {

    private struct File {
        static let registration = "register_data.json"
        static let unregistration = "unregister_data.json"
        static let optInOut = "opt_in_out_data.json"
    }

    private let storage: OptimoveStorage
    private let encoder: JSONEncoder
    private let decoder: JSONDecoder

    init(storage: OptimoveStorage,
         encoder: JSONEncoder,
         decoder: JSONDecoder) {
        self.storage = storage
        self.encoder = encoder
        self.decoder = decoder
    }

    private func getStoragePath(for operation: MbaasOperation) -> String {
        switch operation {
        case .registration:
            return File.registration
        case .unregistration:
            return File.unregistration
        case .optIn, .optOut:
            return File.optInOut
        }
    }

}

extension MbaasBackupImpl: MbaasBackup {

    func backup<T: BaseMbaasModel>(_ model: T) throws {
        let path = getStoragePath(for: model.operation)
        let json = try encoder.encode(model)
        try storage.saveData(data: json, toFileName: path, shared: false)
    }

    func clearLast(for operation: MbaasOperation) throws {
        let path = getStoragePath(for: operation)
        if try storage.isExist(fileName: path, shared: false) {
            try storage.delete(fileName: path, shared: false)
        }
    }

    func restoreLast<T: BaseMbaasModel>(for operation: MbaasOperation) throws -> T {
        let path = getStoragePath(for: operation)
        let data = try storage.load(fileName: path, shared: false)
        return try decoder.decode(T.self, from: data)
    }
}
