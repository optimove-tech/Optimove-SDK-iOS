// Copiright 2019 Optimove

import Foundation

extension Bundle {

    static func getApplicationNameSpace() throws -> String {
        guard let bundleIdentifier = Bundle.main.bundleIdentifier else {
            throw BundleError.noApplicationNameSpace
        }
        return bundleIdentifier
    }

}

enum BundleError: LocalizedError {
    case noApplicationNameSpace

    var errorDescription: String? {
        switch self {
        case .noApplicationNameSpace:
            return "The `CFBundleIdentifier` key is not defined in the tenant's bundle information property list."
        }
    }
}
