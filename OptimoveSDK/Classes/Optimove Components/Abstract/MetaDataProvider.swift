// Copiright 2019 Optimove

import Foundation

protocol MetaData { }

final class MetaDataProvider<T: MetaData> {

    // Not possible yet in Swift to throw an error form var.
    private var metaData: T?

    func setMetaData(_ metaData: T) {
        self.metaData = metaData
    }

    func getMetaData() throws -> T {
        guard let metaData = metaData else {
            throw Error.noMetaData
        }
        return metaData
    }

    enum Error: LocalizedError {
        case noMetaData

        var errorDescription: String? {
            switch self {
            case .noMetaData:
                return "Unable to provide meta data of type: \(T.self)"
            }
        }
    }
}
