import Foundation

class RealtimeEvent: Encodable
{
    var tid:String
    var cid:String?
    var visitorId:String?
    var eid:String
    var firstVisitorDate:String
    var context:[String:Any]
    enum CodingKeys:String,CodingKey
    {
        case tid
        case cid
        case visitorId
        case eid
        case context
        case firstVisitorDate
    }
    struct ContextKey:CodingKey
    {
        var stringValue: String
        
        init?(stringValue: String)
        {
            self.stringValue = stringValue
        }
        
        var intValue: Int?
        
        init?(intValue: Int)
        {
            return nil
        }
    }
    
    init( tid:String, cid:String?,visitorId:String?, eid:String, context:[String:Any])
    {
        self.tid = tid
        self.visitorId = (cid != nil) ? nil : visitorId
        self.cid = cid ?? nil
        self.eid = eid
        self.context = context
        self.firstVisitorDate = "\(Int(OptimoveUserDefaults.shared.firstVisitTimestamp))"
    }
    public func encode(to encoder: Encoder) throws
    {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(tid, forKey: .tid)
        try container.encodeIfPresent(cid, forKey: .cid)
        try container.encodeIfPresent(eid, forKey: .eid)
        try container.encodeIfPresent(visitorId, forKey: .visitorId)
        try container.encodeIfPresent(firstVisitorDate, forKey: .firstVisitorDate)
        
        var contextContainer = container.nestedContainer(keyedBy: ContextKey.self, forKey: .context)
        for (key,value) in context {
            let key = ContextKey(stringValue: key)!
            
            switch value
            {
            case let v as String: try contextContainer.encode(v, forKey: key)
            case let v as Int: try contextContainer.encode(v, forKey: key)
            case let v as Double: try contextContainer.encode(v, forKey: key)
            case let v as Float: try contextContainer.encode(v, forKey: key)
            case let v as Bool: try contextContainer.encode(v, forKey: key)
            default: print("Type \(type(of: value)) not supported")
            }
        }
    }
}
