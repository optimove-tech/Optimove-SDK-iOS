//  Copyright © 2019 Optimove. All rights reserved.

import Foundation

public struct SDK {

    private struct Constants {
        struct Key {
            static let staging = "OPTIMOVE_CLIENT_STG_ENV"
        }
        struct Var {
            static let `true` = "true"
            static let `false` = "false"
        }
    }

    public static var isDebugging: Bool {
        var skip: Bool = false
        assert({ skip = true; return true }())
        return skip
    }

    public static var environment: Environment {
        return isStaging ? .dev : .prod
    }

    public static var isStaging: Bool {
        let envvar = getEnvironmentVariable(for: Constants.Key.staging, defaultValue: Constants.Var.false)
        return envvar == Constants.Var.true
    }

    static func getEnvironmentVariable(for key: String, defaultValue: String) -> String {
        guard let envVarValue = getEnvironmentVariable(for: key), !envVarValue.isEmpty else {
            return defaultValue
        }
        return envVarValue
    }

    static func getEnvironmentVariable(for key: String) -> String? {
        let envvarValue = Bundle.main.object(forInfoDictionaryKey: key) as? String
        return envvarValue?.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
