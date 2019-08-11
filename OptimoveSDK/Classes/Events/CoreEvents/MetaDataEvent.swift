// Copiright 2019 Optimove

final class MetaDataEvent: OptimoveCoreEvent {

    struct Constants {
        static let name = "optimove_sdk_metadata"
        static let sdkPlatform = "iOS"
        struct Key {
            static let sdkVersion = "sdk_version"
            static let configFileURL = "config_file_url"
            static let sdkPlatform = "sdk_platform"
            static let appNS = "app_ns"
        }
    }
    
    let name: String = Constants.name
    let parameters: [String: Any]

    init(configUrl: String, sdkVersion: String, bundleIdentifier: String) {
        parameters = [
            Constants.Key.sdkVersion: sdkVersion,
            Constants.Key.configFileURL: configUrl,
            Constants.Key.sdkPlatform: Constants.sdkPlatform,
            Constants.Key.appNS: bundleIdentifier
        ]
    }

}
