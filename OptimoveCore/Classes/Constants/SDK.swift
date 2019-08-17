//  Copyright © 2019 Optimove. All rights reserved.

import Foundation

public struct SDK {

    private struct Constants {
        struct Bundle {
            static let identifier = "com.optimove.sdk"
        }
        struct Key {
            static let staging = "OPTIMOVE_CLIENT_STG_ENV"
            static let environment = "OPTIMOVE_SDK_ENVIRONMENT"
        }
        struct Var {
            static let `true` = "true"
            static let `false` = "false"
        }
    }

    public static var environment: Environment {
        guard let envvar = getEnvironmentVariable(for: Constants.Key.environment),
              let value = Environment(rawValue: envvar)
        else {
            return .prod
        }
        return value
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
