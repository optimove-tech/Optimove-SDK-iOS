import Foundation

class NotificationExtensionTenantInfo:NSObject
{
    let endpoint: String
    let token: String
    let version: String
    
    init (sharedUserDefaults: UserDefaults)
    {
        self.endpoint = sharedUserDefaults.string(forKey: "configurationEndPoint")!
        self.token = sharedUserDefaults.string(forKey: "tenantToken")!
        self.version =  sharedUserDefaults.string(forKey: "version")!
    }
}
