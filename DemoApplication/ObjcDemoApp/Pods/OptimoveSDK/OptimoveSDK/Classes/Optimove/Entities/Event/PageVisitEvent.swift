

import Foundation

class PageVisitEvent:OptimoveCoreEvent
{
    var params: [String:Any] = [:]
    init(customURL:String, pageTitle:String?, category:String?)
    {
        params["customURL"] = customURL
        params["pageTitle"] = pageTitle ?? nil
        params["category"] = category ?? nil
    }
    var name: String
    {
        return "set_page_visit"
    }
    
    var parameters: [String : Any]
    {
        return params
    }
}
