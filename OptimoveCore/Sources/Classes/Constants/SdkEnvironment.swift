//  Copyright © 2019 Optimove. All rights reserved.

import Foundation

public enum SdkEnvironment {
    public enum Constants {
        public enum Key {
            public static let debugEnabled = "-optimove-debug-enabled"
        }
    }

    public static let isDebugEnabled: Bool = ProcessInfo.processInfo.arguments.contains(Constants.Key.debugEnabled)

    static func getBuildSetting(for key: String, defaultValue: String) -> String {
        guard let envVarValue = getBuildSetting(for: key), !envVarValue.isEmpty else {
            return defaultValue
        }
        return envVarValue
    }

    static func getBuildSetting(for key: String) -> String? {
        let envvarValue = Bundle.main.object(forInfoDictionaryKey: key) as? String
        return envvarValue?.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
