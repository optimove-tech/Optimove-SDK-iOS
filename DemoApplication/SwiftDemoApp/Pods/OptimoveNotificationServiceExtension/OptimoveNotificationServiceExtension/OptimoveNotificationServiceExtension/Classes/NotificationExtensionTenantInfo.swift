import Foundation

@objc public class NotificationExtensionTenantInfo:NSObject
{
    @objc public let endpoint: String
    @objc public let token: String
    @objc public let version: String
    @objc public let appBundleId: String
    
    @objc public init (endpoint: String,
                       token: String,
                       version: String,
                 appBundleId: String) {
        self.endpoint = endpoint
        self.token =  token
        self.version = version
        self.appBundleId = appBundleId
    }
}
