import Foundation

@objc public class NotificationExtensionTenantInfo:NSObject
{
    @objc public let endpoint: String
    @objc public let token: String
    @objc public let version: String
    
    @objc public init (sharedUserDefaults: UserDefaults)
    {
        self.endpoint = sharedUserDefaults.string(forKey: "configurationEndPoint")!
        self.token = sharedUserDefaults.string(forKey: "tenantToken")!
        self.version =  sharedUserDefaults.string(forKey: "version")!
    }
}
