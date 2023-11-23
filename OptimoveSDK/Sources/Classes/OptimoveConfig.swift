//  Copyright © 2022 Optimove. All rights reserved.

import Foundation

/// A set of options for configuring the SDK.
public struct FeatureSet: OptionSet, @unchecked Sendable, CustomStringConvertible {
    public let rawValue: Int

    public static let optimobile = FeatureSet(rawValue: 1 << 1)
    public static let optimove = FeatureSet(rawValue: 1 << 2)
    static let delayedConfiguration = FeatureSet(rawValue: 1 << 3)

    public init(rawValue: Int) {
        self.rawValue = rawValue
    }

    public var description: String {
        var descriptions: [String] = []
        if contains(.optimobile) {
            descriptions.append("Optimobile")
        }
        if contains(.optimove) {
            descriptions.append("Optimove")
        }
        if contains(.delayedConfiguration) {
            descriptions.append("Delayed Configuration")
        }

        return descriptions.isEmpty ? "No Features" : descriptions.joined(separator: ", ")
    }
}

public struct OptimoveConfig {
    let featureSet: FeatureSet
    let tenantInfo: OptimoveTenantInfo?
    let optimobileConfig: OptimobileConfig?

    func isOptimoveConfigured() -> Bool {
        return featureSet.contains(.optimove)
    }

    func isOptimobileConfigured() -> Bool {
        return featureSet.contains(.optimobile)
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
    let credentials: Credentials?
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
    private var credentials: Credentials?
    public private(set) var featureSet: FeatureSet
    private var region: OptimobileConfig.Region?
    private var _tenantToken: String?
    private var _configName: String?
    private var _sessionIdleTimeout: UInt = 23
    private var _inAppConsentStrategy = InAppConsentStrategy.notEnabled
    private var _inAppDisplayMode = InAppDisplayMode.automatic
    private var _inAppDeepLinkHandlerBlock: InAppDeepLinkHandlerBlock?
    private var _pushOpenedHandlerBlock: PushOpenedHandlerBlock?
    private var _pushReceivedInForegroundHandlerBlock: Any?
    private var _deepLinkCname: URL?
    private var _deepLinkHandler: DeepLinkHandler?
    private var _runtimeInfo: [String: AnyObject]?
    private var _sdkInfo: [String: AnyObject]?
    private var _isRelease: Bool?

    public convenience init(optimoveCredentials: String?, optimobileCredentials: String?) {
        self.init()
        setCredentials(optimoveCredentials: optimoveCredentials, optimobileCredentials: optimobileCredentials)
    }

    /// Initialization without credentials.
    /// - Parameter region: ``Region``
    public convenience init(region: Region, featureSet: FeatureSet) {
        self.init()
        self.region = region
        self.featureSet = [featureSet, .delayedConfiguration]
    }

    override public required init() {
        featureSet = []
        super.init()
    }

    @discardableResult public func setCredentials(optimoveCredentials: String?, optimobileCredentials: String?) -> OptimoveConfigBuilder {
        if let optimoveCredentials = optimoveCredentials,
           let args = try? OptimoveArguments(base64: optimoveCredentials)
        {
            _tenantToken = args.tenantToken
            _configName = args.configName
            featureSet.insert(.optimove)
        }
        if let optimobileCredentials = optimobileCredentials,
           let args = try? OptimobileArguments(base64: optimobileCredentials)
        {
            credentials = args.credentials
            region = args.region
            featureSet.insert(.optimobile)
        }
        if featureSet.intersection([.optimove, .optimobile]).isEmpty {
            // TODO: - Throw an error
            Logger.error("Invalid credentials provided to \(OptimoveConfigBuilder.self). At least one of optimoveCredentials or optimobileCredentials are required.")
        }
        return self
    }

    @discardableResult public func setFeatureSet(_ featureSet: FeatureSet) -> OptimoveConfigBuilder {
        self.featureSet = featureSet
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
        let tenantInfo: OptimoveTenantInfo? = {
            if let _tenantToken = _tenantToken,
               let _configName = _configName
            {
                return OptimoveTenantInfo(tenantToken: _tenantToken, configName: _configName)
            }
            Logger.info("\(OptimoveTenantInfo.self) building failed.")
            return nil
        }()

        let optimobileConfig: OptimobileConfig? = {
            if let region = region {
                return OptimobileConfig(
                    credentials: credentials,
                    region: region,
                    sessionIdleTimeout: _sessionIdleTimeout,
                    inAppConsentStrategy: _inAppConsentStrategy,
                    inAppDefaultDisplayMode: _inAppDisplayMode,
                    inAppDeepLinkHandlerBlock: _inAppDeepLinkHandlerBlock,
                    pushOpenedHandlerBlock: _pushOpenedHandlerBlock,
                    _pushReceivedInForegroundHandlerBlock: _pushReceivedInForegroundHandlerBlock,
                    deepLinkCname: _deepLinkCname,
                    deepLinkHandler: _deepLinkHandler,
                    baseUrlMap: UrlBuilder.defaultMapping(for: region.rawValue),
                    runtimeInfo: _runtimeInfo,
                    sdkInfo: _sdkInfo,
                    isRelease: _isRelease
                )
            }
            Logger.info("\(OptimobileConfig.self) building failed.")
            return nil
        }()

        return OptimoveConfig(
            featureSet: featureSet,
            tenantInfo: tenantInfo,
            optimobileConfig: optimobileConfig
        )
    }
}

public extension OptimobileConfig {
    enum Region: String, CaseIterable {
        case EU1 = "eu-central-1"
        case EU2 = "eu-central-2"
        case UK1 = "uk-1"
        case US1 = "us-east-1"

        init(string: String) throws {
            enum Error: Foundation.LocalizedError {
                case failedRepresents(String)

                var errorDescription: String? {
                    switch self {
                    case let .failedRepresents(string):
                        return "Failed on represent the value \(string). Avaliable values are \(Region.allCases.description)"
                    }
                }
            }
            guard let value = OptimobileConfig.Region(rawValue: string) else {
                throw Error.failedRepresents(string)
            }
            self = value
        }
    }
}

struct OptimoveArguments: Decodable {
    enum Error: Foundation.LocalizedError {
        case failedDecodingBase64(String)

        var errorDescription: String? {
            switch self {
            case let .failedDecodingBase64(string):
                return "Failed on decoding base64 the value \(string)"
            }
        }
    }

    let version: Int
    let tenantToken: String
    let configName: String

    enum CodingKeys: String, CodingKey {
        case version
        case tenantToken
        case configName
    }

    init(base64: String) throws {
        guard let data = Data(base64Encoded: base64) else {
            throw Error.failedDecodingBase64(base64)
        }
        self = try JSONDecoder().decode(OptimoveArguments.self, from: data)
    }

    init(from decoder: Decoder) throws {
        var container = try decoder.unkeyedContainer()

        // Assuming the order and type of elements is known and fixed
        version = try container.decode(Int.self)
        tenantToken = try container.decode(String.self)
        configName = try container.decode(String.self)
    }
}

struct OptimobileArguments: Decodable {
    enum Error: Foundation.LocalizedError {
        case failedDecodingBase64(String)

        var errorDescription: String? {
            switch self {
            case let .failedDecodingBase64(string):
                return "Failed on decoding base64 the value \(string)"
            }
        }
    }

    let version: Int
    let region: OptimobileConfig.Region
    var credentials: Credentials

    enum CodingKeys: String, CodingKey {
        case version
        case region
        case credentials
    }

    init(base64: String) throws {
        guard let data = Data(base64Encoded: base64) else {
            throw Error.failedDecodingBase64(base64)
        }
        self = try JSONDecoder().decode(OptimobileArguments.self, from: data)
    }

    init(from decoder: Decoder) throws {
        var container = try decoder.unkeyedContainer()

        // Assuming the order and type of elements is known and fixed
        version = try container.decode(Int.self)
        let regionString = try container.decode(String.self)
        let apiKey = try container.decode(String.self)
        let secretKey = try container.decode(String.self)

        region = try OptimobileConfig.Region(string: regionString)
        credentials = Credentials(apiKey: apiKey, secretKey: secretKey)
    }
}
