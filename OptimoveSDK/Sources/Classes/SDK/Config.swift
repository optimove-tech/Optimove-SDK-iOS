// Copyright © 2022 Optimove. All rights reserved.

import Foundation

public struct Config {
    let apiKey: String
    let secretKey: String

    let sessionIdleTimeout: UInt

    let inAppConsentStrategy : InAppConsentStrategy
    let inAppDeepLinkHandlerBlock : InAppDeepLinkHandlerBlock?

    let pushOpenedHandlerBlock : PushOpenedHandlerBlock?
    fileprivate let _pushReceivedInForegroundHandlerBlock : Any?
    @available(iOS 10.0, *)
    var pushReceivedInForegroundHandlerBlock: PushReceivedInForegroundHandlerBlock? {
        get {
            return _pushReceivedInForegroundHandlerBlock as? PushReceivedInForegroundHandlerBlock
        }
    }

    let deepLinkCname : URL?
    let deepLinkHandler : DeepLinkHandler?

    let baseUrlMap : ServiceUrlMap
}

open class ConfigBuilder: NSObject {
    private var _region: String
    private var _apiKey: String
    private var _secretKey: String
    private var _sessionIdleTimeout: UInt
    private var _inAppConsentStrategy = InAppConsentStrategy.NotEnabled
    private var _inAppDeepLinkHandlerBlock: InAppDeepLinkHandlerBlock?
    private var _pushOpenedHandlerBlock: PushOpenedHandlerBlock?
    private var _pushReceivedInForegroundHandlerBlock: Any?
    private var _deepLinkCname : URL?
    private var _deepLinkHandler : DeepLinkHandler?
    private var _baseUrlMap : ServiceUrlMap
    
    public init(region: String, apiKey: String, secretKey: String) {
        _region = region
        _apiKey = apiKey
        _secretKey = secretKey
        _sessionIdleTimeout = 23
        _baseUrlMap = UrlBuilder.defaultMapping(region: region)
    }
    
    @discardableResult public func setSessionIdleTimeout(seconds: UInt) -> ConfigBuilder {
        _sessionIdleTimeout = seconds
        return self
    }
    
    @discardableResult public func enableInAppMessaging(inAppConsentStrategy: InAppConsentStrategy) -> ConfigBuilder {
        _inAppConsentStrategy = inAppConsentStrategy
        return self
    }
    
    @discardableResult public func setInAppDeepLinkHandler(inAppDeepLinkHandlerBlock: @escaping InAppDeepLinkHandlerBlock) -> ConfigBuilder {
        _inAppDeepLinkHandlerBlock = inAppDeepLinkHandlerBlock
        return self
    }
    
    @discardableResult public func setPushOpenedHandler(pushOpenedHandlerBlock: @escaping PushOpenedHandlerBlock) -> ConfigBuilder {
        _pushOpenedHandlerBlock = pushOpenedHandlerBlock
        return self
    }
    
    @available(iOS 10.0, *)
    @discardableResult public func setPushReceivedInForegroundHandler(pushReceivedInForegroundHandlerBlock: @escaping PushReceivedInForegroundHandlerBlock) -> ConfigBuilder {
        _pushReceivedInForegroundHandlerBlock = pushReceivedInForegroundHandlerBlock
        return self
    }

   @discardableResult public func enableDeepLinking(cname: String? = nil, _ handler: @escaping DeepLinkHandler) -> ConfigBuilder {
        _deepLinkCname = URL(string: cname ?? "")
        _deepLinkHandler = handler

        return self
    }

    /**
     Internal SDK embedding API, do not call or depend on this method in your app
     */
    @discardableResult public func setBaseUrlMapping(baseUrlMap:ServiceUrlMap) -> ConfigBuilder {
        _baseUrlMap = baseUrlMap

        return self
    }
    
    @discardableResult public func build() -> Config {
        return Config(
            apiKey: _apiKey,
            secretKey: _secretKey,
            sessionIdleTimeout: _sessionIdleTimeout,
            inAppConsentStrategy: _inAppConsentStrategy,
            inAppDeepLinkHandlerBlock: _inAppDeepLinkHandlerBlock,
            pushOpenedHandlerBlock: _pushOpenedHandlerBlock,
            _pushReceivedInForegroundHandlerBlock: _pushReceivedInForegroundHandlerBlock,
            deepLinkCname: nil,
            deepLinkHandler: _deepLinkHandler,
            baseUrlMap: _baseUrlMap
        )
    }
}
