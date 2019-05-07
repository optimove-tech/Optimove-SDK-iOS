import Foundation

class EnvVars {

    static let sdkEnv: SdkEnv = .prod


    static var isClientStgEnv: Bool {
        let rawValue = getEnvVar(for: "OPTIMOVE_CLIENT_STG_ENV", defaultValue: "false")!
        return NSString(string:rawValue.trimmingCharacters(in: .whitespacesAndNewlines)).boolValue
    }

    static var minLogLevelToShow: LogLevel = {
        if let minLogLevel = EnvVars.minLogLevelEnv {
            return minLogLevel
        }
        if EnvVars.sdkEnv == .dev {
            return LogLevel.debug
        }
        return EnvVars.isClientStgEnv ? LogLevel.info : LogLevel.warn
    }()

    private static var minLogLevelEnv: LogLevel? {
        guard let levelStr = getEnvVar(for: "OPTIMOVE_MIN_LOG_LEVEL") else { return nil }
        switch levelStr.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() {
        case "debug":
            return LogLevel(rawValue: 0)
        case "info":
            return LogLevel(rawValue: 1)
        case "warn":
            return LogLevel(rawValue: 2)
        case "error":
            return LogLevel(rawValue: 3)
        default:
            return nil
        }
    }

    private static func getEnvVar(for key: String, defaultValue: String? = nil) -> String? {
        guard let keyVal = Bundle.main.object(forInfoDictionaryKey: key) as? String else { return defaultValue }
        return keyVal.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? defaultValue : keyVal
    }
}
