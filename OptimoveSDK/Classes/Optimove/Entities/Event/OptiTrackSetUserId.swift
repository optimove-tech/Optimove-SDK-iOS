

import Foundation


class SetUserId :OptimoveCoreEvent
{
    init(originalVistorId:String,userId:String,updateVisitorId:String) {
        self.originalVistorId = originalVistorId
        self.userId = userId
        self.updatedVisitorId = updateVisitorId
    }
    let originalVistorId:String
    let userId:String
    let updatedVisitorId:String
    
    
    var name: String
    {
        return "set_user_id_event"
    }
    var parameters: [String : Any]
    {
        guard  CustomerID != nil else {
            OptiLogger.error("customer id nil")
            return [:]
        }
        
        return [OptimoveKeys.Configuration.originalVisitorId.rawValue   : originalVistorId as Any,
                OptimoveKeys.Configuration.realtimeUserId.rawValue      : userId as Any,
                "updatedVisitorId": updatedVisitorId ]
        
    }
}

