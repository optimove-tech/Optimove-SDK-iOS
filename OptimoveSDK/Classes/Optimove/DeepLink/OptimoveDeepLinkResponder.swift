

import Foundation

@objc public protocol OptimoveDeepLinkCallback
{
    @objc func didReceive(deepLink: OptimoveDeepLinkComponents?)
}

@objc public class OptimoveDeepLinkResponder: NSObject
{
    private let deepLinkCallback: OptimoveDeepLinkCallback
    
    @objc public init(_ deepLinkCallback: OptimoveDeepLinkCallback)
    {
        self.deepLinkCallback = deepLinkCallback
    }
    
    @objc func didReceive(deepLinkComponent: OptimoveDeepLinkComponents)
    {
        deepLinkCallback.didReceive(deepLink: deepLinkComponent)
    }
}

@objc public class OptimoveDeepLinkComponents:NSObject
{
    @objc public var screenName : String
    @objc public var query: [String:String]?
    
    @objc init(screenName: String, query:[String:String]?) {
        self.screenName = screenName
        self.query = query
    }
    
}
