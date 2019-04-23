import Foundation

class MbaasOperation {
    var tenantId: Int
    init() {
        tenantId = TenantID ?? -1
    }
}
