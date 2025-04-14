//  Copyright © 2022 Optimove. All rights reserved.

import Foundation

/// A set of options for configuring the SDK.
/// - Note: The SDK can be configured to support multiple features.
/// - Tag: Feature
/// - SeeAlso: ``OptimoveConfigBuilder``
public struct Feature: OptionSet, @unchecked Sendable, CustomStringConvertible {
    public let rawValue: Int

    /// Optimobile feature.
    public static let optimobile = Feature(rawValue: 1 << 1)
    /// Optimove feature.
    public static let optimove = Feature(rawValue: 1 << 2)
    /// Preference center feature.
    public static let preferenceCenter = Feature(rawValue: 1 << 4)
    /// Embedded messaing feature
    public static let embeddedMessaging = Feature(rawValue: 1 << 4)

    static let delayedConfiguration = Feature(rawValue: 1 << 3)

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
        if contains(.preferenceCenter) {
            descriptions.append("Preference Center")
        }

        return descriptions.isEmpty ? "No Features" : descriptions.joined(separator: ", ")
    }
}

public struct OptimoveConfig {
    let features: Feature
    let tenantInfo: OptimoveTenantInfo?
    let optimobileConfig: OptimobileConfig?
    let preferenceCenterConfig: PreferenceCenterConfig?
    let embeddedMessagingConfig: EmbeddedMessagingConfig?

    func isOptimoveConfigured() -> Bool {
        return features.contains(.optimove)
    }

    func isOptimobileConfigured() -> Bool {
        return features.contains(.optimobile)
    }
    
    func isPreferenceCenterConfigured() -> Bool {
        return features.contains(.preferenceCenter)
    }

    func getPreferenceCenterConfig() -> PreferenceCenterConfig? {
        return preferenceCenterConfig
    }
    
    func isEmbeddedMessagingConfigured() -> Bool {
        return features.contains(.embeddedMessaging)
    }

    func getEmbeddedMessagingConfig() -> EmbeddedMessagingConfig? {
        return embeddedMessagingConfig
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
    let credentials: OptimobileCredentials?
    let region: Region
    let urlBuilder: UrlBuilder

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

    let runtimeInfo: [String: AnyObject]?
    let sdkInfo: [String: AnyObject]?
    let isRelease: Bool?
}

public typealias Region = OptimobileConfig.Region

open class OptimoveConfigBuilder: NSObject {
    private var credentials: OptimobileCredentials?
    private var preferenceCenterCredentials: String?
    private var embeddedMessagingCredentials: String?
    public private(set) var features: Feature
    var region: OptimobileConfig.Region?
    var urlBuilder: UrlBuilder
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

    /// Intent to use for intialization for delayed configuration.
    /// - Parameter region: ``Region`` - region to be configured.
    /// - Parameter features: ``Feature`` - single or multiple features to be configured.
    ///
    /// - Multiple feature usage example: `OptimoveConfigBuilder(region: .US, features: [.optimove, .optimobile])`
    public convenience init(region: Region, features: Feature) {
        self.init()
        self.region = region
        self.features = [features, .delayedConfiguration]
    }

    convenience init(from config: OptimoveConfig) {
        self.init()
        if let tenantInfo = config.tenantInfo {
            _tenantToken = tenantInfo.tenantToken
            _configName = tenantInfo.configName
        }
        if let optimobileConfig = config.optimobileConfig {
            credentials = optimobileConfig.credentials
            region = optimobileConfig.region
            urlBuilder = optimobileConfig.urlBuilder
            _sessionIdleTimeout = optimobileConfig.sessionIdleTimeout
            _inAppConsentStrategy = optimobileConfig.inAppConsentStrategy
            _inAppDisplayMode = optimobileConfig.inAppDefaultDisplayMode
            _inAppDeepLinkHandlerBlock = optimobileConfig.inAppDeepLinkHandlerBlock
            _pushOpenedHandlerBlock = optimobileConfig.pushOpenedHandlerBlock
            _pushReceivedInForegroundHandlerBlock = optimobileConfig._pushReceivedInForegroundHandlerBlock
            _deepLinkCname = optimobileConfig.deepLinkCname
            _deepLinkHandler = optimobileConfig.deepLinkHandler
            _runtimeInfo = optimobileConfig.runtimeInfo
            _sdkInfo = optimobileConfig.sdkInfo
            _isRelease = optimobileConfig.isRelease
        }
        features = config.features
    }

    override public required init() {
        features = []
        urlBuilder = UrlBuilder(storage: KeyValPersistenceHelper.self)
        super.init()
    }

    @discardableResult func setCredentials(
        optimoveCredentials: String?,
        optimobileCredentials: String?,
        preferenceCenterCredentials: String? = nil,
        embeddedMessagingCredentials: String? = nil
    ) -> OptimoveConfigBuilder {
        if optimoveCredentials == nil, optimobileCredentials == nil {
            assertionFailure("Should provide at least optimove or optimobile credentials")
        }

        if let optimoveCredentials = optimoveCredentials, !optimoveCredentials.isEmpty {
            do {
                let args = try OptimoveArguments(base64: optimoveCredentials)
                features.insert(.optimove)
                _tenantToken = args.tenantToken
                _configName = args.configName
            } catch {
                Logger.error("Invalid Optimove credentials: \(error.localizedDescription)")
            }
        }

        if let optimobileCredentials = optimobileCredentials, !optimobileCredentials.isEmpty {
            do {
                let args = try OptimobileArguments(base64: optimobileCredentials)
                features.insert(.optimobile)
                credentials = args.credentials
                region = args.region
            } catch {
                Logger.error("Invalid Optimobile credentials: \(error.localizedDescription)")
            }
        }

        if let preferenceCenterCredentials = preferenceCenterCredentials, !preferenceCenterCredentials.isEmpty {
            if optimoveCredentials == nil || optimoveCredentials == "" {
                Logger.error("Preference Center requires optimove credentials set");
            }  else {
                self.preferenceCenterCredentials = preferenceCenterCredentials
                features.insert(.preferenceCenter)
            }
        }
        
        if let embeddedMessagingCredentials = embeddedMessagingCredentials, !embeddedMessagingCredentials.isEmpty {
            if optimoveCredentials == nil || optimoveCredentials == "" {
                Logger.error("Embedded Center requires optimove credentials set");
            }  else {
                self.embeddedMessagingCredentials = embeddedMessagingCredentials
                features.insert(.embeddedMessaging)
            }
        }

        return self
    }

    @discardableResult public func setFeatures(_ features: Feature) -> OptimoveConfigBuilder {
        self.features = features
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

    @discardableResult public func enablePreferenceCenter(credentials: String) -> OptimoveConfigBuilder
    {
        features.insert(.preferenceCenter)
        preferenceCenterCredentials = credentials

        return self
    }
    
    @discardableResult public func enableEmbeddedMessaging(credentials: String) -> OptimoveConfigBuilder
    {
        features.insert(.embeddedMessaging)
        embeddedMessagingCredentials = credentials

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

    /**
     Internal SDK embedding API, do not call or depend on this method in your app
     */
    @discardableResult public func setBaseUrlMapping(baseUrlMap: UrlBuilder.ServiceUrlMap) -> OptimoveConfigBuilder {
        urlBuilder.runtimeUrlsMap = baseUrlMap

        return self
    }

    @discardableResult public func build() -> OptimoveConfig {
        if features.intersection([.optimove, .optimobile]).isEmpty {
            Logger.error("No features enabled. Please enable at least one feature.")
        }

        let tenantInfo: OptimoveTenantInfo? = {
            if features.contains(.optimove),
               let _tenantToken = _tenantToken,
               let _configName = _configName
            {
                return OptimoveTenantInfo(tenantToken: _tenantToken, configName: _configName)
            }
            Logger.info("\(OptimoveTenantInfo.self) building skipped.")
            return nil
        }()

        let optimobileConfig: OptimobileConfig? = {
            if features.contains(.optimobile),
               let region = region
            {
                return OptimobileConfig(
                    credentials: credentials,
                    region: region,
                    urlBuilder: urlBuilder,
                    sessionIdleTimeout: _sessionIdleTimeout,
                    inAppConsentStrategy: _inAppConsentStrategy,
                    inAppDefaultDisplayMode: _inAppDisplayMode,
                    inAppDeepLinkHandlerBlock: _inAppDeepLinkHandlerBlock,
                    pushOpenedHandlerBlock: _pushOpenedHandlerBlock,
                    _pushReceivedInForegroundHandlerBlock: _pushReceivedInForegroundHandlerBlock,
                    deepLinkCname: _deepLinkCname,
                    deepLinkHandler: _deepLinkHandler,
                    runtimeInfo: _runtimeInfo,
                    sdkInfo: _sdkInfo,
                    isRelease: _isRelease
                )
            }
            Logger.info("\(OptimobileConfig.self) building skipped.")
            return nil
        }()

        let preferenceCenterConfig: PreferenceCenterConfig? = {
            if !features.contains(.optimove),
               tenantInfo == nil,
               !features.contains(.delayedConfiguration) {
                Logger.error("Preference center cannot be inialized without optimove")
                return nil
            }

            if preferenceCenterCredentials == nil {
                if !features.contains(.delayedConfiguration) {
                    Logger.error("Preference center could not be initialized due to missing credentials.")
                }
                return nil
            }

            return getPreferenceCenterConfig(from: preferenceCenterCredentials)
        }()
        
        let embeddedMessagingConfig: EmbeddedMessagingConfig? = {
            if !features.contains(.optimove),
               tenantInfo == nil,
               !features.contains(.delayedConfiguration) {
                Logger.error("Embedded messaging cannot be inialized without optimove")
                return nil
            }

            if embeddedMessagingCredentials == nil {
                if !features.contains(.delayedConfiguration) {
                    Logger.error("Embedded Messaging could not be initialized due to missing credentials.")
                }
                return nil
            }

            return getEmbeddedMessagingConfig(from: embeddedMessagingCredentials)
        }()


        return OptimoveConfig(
            features: features,
            tenantInfo: tenantInfo,
            optimobileConfig: optimobileConfig,
            preferenceCenterConfig: preferenceCenterConfig
        )
    }

    private func getPreferenceCenterConfig(from credentials: String?) -> PreferenceCenterConfig? {
        do {
            let args = try PreferenceCenterArguments(base64: credentials!)

            return PreferenceCenterConfig(
                region: args.region,
                tenantId: args.tenantId,
                brandGroupId: args.brandGroupId
            )
        } catch {
            Logger.error("Invalid preference center credentials: \(error.localizedDescription)")
            return nil
        }
    }
    
    private func getEmbeddedMessagingConfig(from credentials: String?) -> EmbeddedMessagingConfig? {
        do {
            let args = try EmbeddedMessagingArguments(base64: credentials!)

            return EmbeddedMessagingConfig(
                region: args.region,
                tenantId: args.tenantId,
                brandGroupId: args.brandGroupId
            )
        } catch {
            Logger.error("Invalid embedded messaging credentials: \(error.localizedDescription)")
            return nil
        }
    }
}

public extension OptimobileConfig {
    enum Region: String, CaseIterable, Codable {
        case DEV = "uk-1"
        case EU = "eu-central-2"
        case US = "us-east-1"

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
        case emptyBase64
        case failedDecodingBase64(String)

        var errorDescription: String? {
            switch self {
            case .emptyBase64:
                return "The base64 string is empty"
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
        guard !base64.isEmpty else {
            throw Error.emptyBase64
        }
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
        case emptyBase64
        case failedDecodingBase64(String)

        var errorDescription: String? {
            switch self {
            case .emptyBase64:
                return "The base64 string is empty"
            case let .failedDecodingBase64(string):
                return "Failed on decoding base64 the value \(string)"
            }
        }
    }

    let version: Int
    let region: OptimobileConfig.Region
    var credentials: OptimobileCredentials

    enum CodingKeys: String, CodingKey {
        case version
        case region
        case credentials
    }

    init(base64: String) throws {
        guard !base64.isEmpty else {
            throw Error.emptyBase64
        }
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
        credentials = OptimobileCredentials(apiKey: apiKey, secretKey: secretKey)
    }
}

struct BaseArguments: Decodable {
    let version: String
    let region: String
    let tenantId: Int
    let brandGroupId: String

    enum CodingKeys: String, CodingKey {
        case version
        case environment
        case tenantId
        case brandGroupId
    }

    init(from decoder: Decoder) throws {
        var container = try decoder.unkeyedContainer()

        version = try container.decode(String.self)
        region = try container.decode(String.self)
        tenantId = try container.decode(Int.self)
        brandGroupId = try container.decode(String.self)
    }

    init(base64: String) throws {
        guard !base64.isEmpty else {
            throw Base64DecodingError.emptyBase64
        }
        guard let data = Data(base64Encoded: base64) else {
            throw Base64DecodingError.failedDecodingBase64(base64)
        }
        self = try JSONDecoder().decode(BaseArguments.self, from: data)
    }
}

typealias PreferenceCenterArguments = BaseArguments
typealias EmbeddedMessagingArguments = BaseArguments
