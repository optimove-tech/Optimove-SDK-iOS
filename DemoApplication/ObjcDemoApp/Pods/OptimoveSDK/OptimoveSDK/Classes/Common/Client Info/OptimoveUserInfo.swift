
import Foundation
struct OptimoveUserInfo {
    let visitorId:String
    var userId:String?
    
    init() {
        guard OptimoveUserDefaults.shared.visitorID != nil else {
            OptiLogger.debug("first initializtion, generate new visitor id")
            let uuid = UUID().uuidString
            let sanitizedUUID = uuid.replacingOccurrences(of: "-", with: "")
            let start = sanitizedUUID.startIndex
            let end = sanitizedUUID.index(start, offsetBy: 16)
            visitorId = String(sanitizedUUID[start..<end])
            OptimoveUserDefaults.shared.visitorID = visitorId
            OptimoveUserDefaults.shared.initialVisitorId = visitorId
            return
        }
        
        visitorId = OptimoveUserDefaults.shared.visitorID!
        userId = OptimoveUserDefaults.shared.customerID
    }
}
