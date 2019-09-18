import Foundation

final class SDK {

    private struct Constants {
        struct Bundle {
            static let identifier = "com.optimove.sdk"
        }
        struct Key {
            static let staging = "OPTIMOVE_CLIENT_STG_ENV"
            static let logLevel = "OPTIMOVE_MIN_LOG_LEVEL"
            static let environment = "OPTIMOVE_SDK_ENVIRONMENT"
        }
        struct Var {
            static let `true` = "true"
            static let `false` = "false"
        }
    }

    static var environment: Environment {
        guard let envvar = getEnvironmentVariable(for: Constants.Key.environment),
              let value = Environment(rawValue: envvar)
        else {
            return .prod
        }
        return value
    }

    static var version: String = "2.2.3"

    static var isStaging: Bool {
        let envvar = getEnvironmentVariable(for: Constants.Key.staging, defaultValue: Constants.Var.false)
        return envvar == Constants.Var.true
    }

    static var logLevelToShow: LogLevel = {
        if let minLogLevel = SDK.logLevel {
            return minLogLevel
        }
        return SDK.isStaging ? LogLevel.info : LogLevel.warn
    }()

    private static var logLevel: LogLevel? {
        guard let levelStr = getEnvironmentVariable(for: Constants.Key.logLevel) else { return nil }
        return LogLevel(string: levelStr.lowercased())
    }

    private static func getEnvironmentVariable(for key: String, defaultValue: String) -> String {
        guard let envVarValue = getEnvironmentVariable(for: key), !envVarValue.isEmpty else {
            return defaultValue
        }
        return envVarValue
    }

    private static func getEnvironmentVariable(for key: String) -> String? {
        let envvarValue = Bundle.main.object(forInfoDictionaryKey: key) as? String
        return envvarValue?.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
