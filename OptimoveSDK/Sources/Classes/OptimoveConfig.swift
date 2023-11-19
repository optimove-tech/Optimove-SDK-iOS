//  Copyright © 2022 Optimove. All rights reserved.

import Foundation

public struct OptimoveConfig {
    let tenantInfo: OptimoveTenantInfo?
    let optimobileConfig: OptimobileConfig?

    func isOptimoveConfigured() -> Bool {
        return tenantInfo != nil
    }

    func isOptimobileConfigured() -> Bool {
        return optimobileConfig != nil
    }
}

@objc public class OptimoveTenantInfo: NSObject {
    @objc public var tenantToken: String
    @objc public var configName: String

    @objc public init(tenantToken: String, configName: String) {
        self.tenantToken = tenantToken
        self.configName = configName
    }
}

public struct OptimobileConfig {
    struct Credentials {
        let apiKey: String
        let secretKey: String
    }
    /// Optimove initialization strategy.
    public enum InitializationStrategy: UInt8 {
        case none = 0
        case optimobileOnly = 1
        case optimoveOnly = 2
        case all = 3
        /// Union of two initialization strategies.
        /// - Parameters:
        ///   - lhs: ``InitializationStrategy`` instance.
        ///   - rhs: ``InitializationStrategy`` instance.
        /// - Returns: Union of two initialization strategies.
        static func | (lhs: InitializationStrategy, rhs: InitializationStrategy) -> InitializationStrategy {
            return InitializationStrategy(rawValue: lhs.rawValue | rhs.rawValue)!
        }
    }

    public enum Region: String {
        case EU = "eu"
        case US = "us"
    }

    let initializationStrategy: InitializationStrategy
    let region: Region

    let sessionIdleTimeout: UInt

    let inAppConsentStrategy: InAppConsentStrategy
    let inAppDefaultDisplayMode: InAppDisplayMode
    let inAppDeepLinkHandlerBlock: InAppDeepLinkHandlerBlock?

    let pushOpenedHandlerBlock: PushOpenedHandlerBlock?
    fileprivate let _pushReceivedInForegroundHandlerBlock: Any?
    @available(iOS 10.0, *)
    var pushReceivedInForegroundHandlerBlock: PushReceivedInForegroundHandlerBlock? {
        return _pushReceivedInForegroundHandlerBlock as? PushReceivedInForegroundHandlerBlock
    }

    let deepLinkCname: URL?
    let deepLinkHandler: DeepLinkHandler?

    let baseUrlMap: UrlBuilder.ServiceUrlMap

    let runtimeInfo: [String: AnyObject]?
    let sdkInfo: [String: AnyObject]?
    let isRelease: Bool?
}

public typealias Region = OptimobileConfig.Region

open class OptimoveConfigBuilder: NSObject {
    private var credentials: OptimobileConfig.Credentials?
    private var region: OptimobileConfig.Region?
    private var initializationStrategy: OptimobileConfig.InitializationStrategy
    private var _tenantToken: String?
    private var _configName: String?
    private var _sessionIdleTimeout: UInt
    private var _inAppConsentStrategy = InAppConsentStrategy.notEnabled
    private var _inAppDisplayMode = InAppDisplayMode.automatic
    private var _inAppDeepLinkHandlerBlock: InAppDeepLinkHandlerBlock?
    private var _pushOpenedHandlerBlock: PushOpenedHandlerBlock?
    private var _pushReceivedInForegroundHandlerBlock: Any?
    private var _deepLinkCname: URL?
    private var _deepLinkHandler: DeepLinkHandler?
    private var _baseUrlMap: UrlBuilder.ServiceUrlMap?

    private var _runtimeInfo: [String: AnyObject]?
    private var _sdkInfo: [String: AnyObject]?
    private var _isRelease: Bool?

    public convenience init(optimoveCredentials: String?, optimobileCredentials: String?) {
        self.init()
        var initilazationStrategise: Set<OptimobileConfig.InitializationStrategy> = []
        
        if let optimoveCredentials = OptimoveConfigBuilder.parseOptimoveCredentials(creds: optimoveCredentials) {
            _tenantToken = optimoveCredentials.tenantToken
            _configName = optimoveCredentials.configName
            initilazationStrategise.insert(.optimoveOnly)
        }

        if let optimobileCredentials = OptimoveConfigBuilder.parseOptimobileCredentials(creds: optimobileCredentials) {
            credentials = optimobileCredentials.credentials
            region = optimobileCredentials.region

            _baseUrlMap = UrlBuilder.defaultMapping(for: optimobileCredentials.region.rawValue)
            
            initilazationStrategise.insert(.optimobileOnly)
        }
        
        initializationStrategy = initilazationStrategise.reduce(.none, |)
        
        if initializationStrategy == .none {
            assertionFailure("Invalid credentials provided to OptimoveConfigBuilder. At least one of optimoveCredentials or optimobileCredentials are required.")
        }
    }

    /// Initialization without credentials.
    /// - Parameter region: ``Region``
    public convenience init(region: Region) {
        self.init()
        self.region = region
    }

    override public required init() {
        _sessionIdleTimeout = 23
        initializationStrategy = .none
        super.init()
    }

    @discardableResult public func bootOptiMobile(_ region: Region) -> OptimoveConfigBuilder {
        self.region = region
        return self
    }

    @discardableResult public func setSessionIdleTimeout(seconds: UInt) -> OptimoveConfigBuilder {
        _sessionIdleTimeout = seconds
        return self
    }

    @discardableResult public func enableInAppMessaging(inAppConsentStrategy: InAppConsentStrategy, defaultDisplayMode: InAppDisplayMode) -> OptimoveConfigBuilder {
        _inAppConsentStrategy = inAppConsentStrategy
        _inAppDisplayMode = defaultDisplayMode
        return self
    }

    @discardableResult public func enableInAppMessaging(inAppConsentStrategy: InAppConsentStrategy) -> OptimoveConfigBuilder {
        return enableInAppMessaging(inAppConsentStrategy: inAppConsentStrategy, defaultDisplayMode: .automatic)
    }

    @discardableResult public func setInAppDeepLinkHandler(inAppDeepLinkHandlerBlock: @escaping InAppDeepLinkHandlerBlock) -> OptimoveConfigBuilder {
        _inAppDeepLinkHandlerBlock = inAppDeepLinkHandlerBlock
        return self
    }

    @discardableResult public func setPushOpenedHandler(pushOpenedHandlerBlock: @escaping PushOpenedHandlerBlock) -> OptimoveConfigBuilder {
        _pushOpenedHandlerBlock = pushOpenedHandlerBlock
        return self
    }

    @available(iOS 10.0, *)
    @discardableResult public func setPushReceivedInForegroundHandler(pushReceivedInForegroundHandlerBlock: @escaping PushReceivedInForegroundHandlerBlock) -> OptimoveConfigBuilder {
        _pushReceivedInForegroundHandlerBlock = pushReceivedInForegroundHandlerBlock
        return self
    }

    @discardableResult public func enableDeepLinking(cname: String? = nil, _ handler: @escaping DeepLinkHandler) -> OptimoveConfigBuilder {
        _deepLinkCname = URL(string: cname ?? "")
        _deepLinkHandler = handler

        return self
    }

    /**
     Internal SDK embedding API to support override of stats data in x-plat SDKs. Do not call or depend on this method in your app
     */
    @discardableResult public func setRuntimeInfo(runtimeInfo: [String: AnyObject]) -> OptimoveConfigBuilder {
        _runtimeInfo = runtimeInfo

        return self
    }

    /**
     Internal SDK embedding API to support override of stats data in x-plat SDKs. Do not call or depend on this method in your app
     */
    @discardableResult public func setSdkInfo(sdkInfo: [String: AnyObject]) -> OptimoveConfigBuilder {
        _sdkInfo = sdkInfo

        return self
    }

    /**
     Internal SDK embedding API to support override of stats data in x-plat SDKs. Do not call or depend on this method in your app
     */
    @discardableResult public func setTargetType(isRelease: Bool) -> OptimoveConfigBuilder {
        _isRelease = isRelease

        return self
    }

    @discardableResult public func build() -> OptimoveConfig {
        var tenantInfo: OptimoveTenantInfo?
        var optimobileConfig: OptimobileConfig?

        if let _tenantToken = _tenantToken, let _configName = _configName {
            tenantInfo = OptimoveTenantInfo(tenantToken: _tenantToken, configName: _configName)
        }

        if let region = region,
           let _baseUrlMap = _baseUrlMap
        {
            optimobileConfig = OptimobileConfig(
                credentials: credentials,
                initializationStrategy: initializationStrategy,
                region: region,
                sessionIdleTimeout: _sessionIdleTimeout,
                inAppConsentStrategy: _inAppConsentStrategy,
                inAppDefaultDisplayMode: _inAppDisplayMode,
                inAppDeepLinkHandlerBlock: _inAppDeepLinkHandlerBlock,
                pushOpenedHandlerBlock: _pushOpenedHandlerBlock,
                _pushReceivedInForegroundHandlerBlock: _pushReceivedInForegroundHandlerBlock,
                deepLinkCname: _deepLinkCname,
                deepLinkHandler: _deepLinkHandler,
                baseUrlMap: _baseUrlMap,
                runtimeInfo: _runtimeInfo,
                sdkInfo: _sdkInfo,
                isRelease: _isRelease
            )
        }

        return OptimoveConfig(
            tenantInfo: tenantInfo,
            optimobileConfig: optimobileConfig
        )
    }

    private static func parseOptimoveCredentials(creds: String?) -> (tenantToken: String, configName: String)? {
        guard let creds = creds,
              let tuple = try? parseTuple(base64: creds),
              let ver = tuple[0] as? Int
        else {
            return nil
        }

        if ver != 1 {
            assertionFailure("Incompatible credentials version given, please update the SDK version or check credentials")
        }

        guard let tenantToken = tuple[1] as? String,
              let configName = tuple[2] as? String
        else {
            return nil
        }

        return (tenantToken, configName)
    }

    private static func parseOptimobileCredentials(creds: String?) -> (region: OptimobileConfig.Region, credentials: OptimobileConfig.Credentials)? {
        guard let creds = creds,
              let tuple = try? parseTuple(base64: creds),
              let ver = tuple[0] as? Int
        else {
            return nil
        }

        if ver != 1 {
            assertionFailure("Incompatible credentials version given, please update the SDK version or check credentials")
        }

        guard
            let regionRaw = tuple[1] as? String,
            let region = OptimobileConfig.Region(rawValue: regionRaw),
            let apiKeyRaw = tuple[2] as? String,
            let secretKeyRaw = tuple[3] as? String
        else {
            return nil
        }

        return (region, OptimobileConfig.Credentials(apiKey: apiKeyRaw, secretKey: secretKeyRaw))
    }

    enum Error: Foundation.LocalizedError {
        case failedDecodingBase64(String)
        case failedSerialize(data: Data, to: Any.Type)

        var errorDescription: String? {
            switch self {
            case let .failedDecodingBase64(string):
                "Failed on decoding base64 value \(string)"
            case let .failedSerialize(data: data, to: type):
                "Failed to serialize data length \(data.count) to type \(type.self)"
            }
        }
    }

    private static func parseTuple(base64: String) throws -> [Any] {
        guard let data = Data(base64Encoded: base64) else {
            throw Error.failedDecodingBase64(base64)
        }
        guard let result = try JSONSerialization.jsonObject(with: data) as? [Any] else {
            throw Error.failedSerialize(data: data, to: [Any].self)
        }
        return result
    }
}
