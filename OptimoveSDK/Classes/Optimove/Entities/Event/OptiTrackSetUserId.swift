

import Foundation


class SetUserId :OptimoveCoreEvent
{
    let originalVistorId:String
    let userId:String
    let updatedVisitorId:String


    var name: String
    {
        return "set_user_id_event"
    }
    var parameters: [String : Any]
   
    init(originalVistorId:String,userId:String,updateVisitorId:String) {
        self.originalVistorId = originalVistorId
        self.userId = userId
        self.updatedVisitorId = updateVisitorId

        guard CustomerID != nil else {
            OptiLogger.error("customer id nil")
            self.parameters = [:]
            return
        }

        self.parameters = [OptimoveKeys.Configuration.originalVisitorId.rawValue   : originalVistorId as Any,
                OptimoveKeys.Configuration.realtimeUserId.rawValue      : userId as Any,
                "updatedVisitorId": updatedVisitorId ]


    }
}

