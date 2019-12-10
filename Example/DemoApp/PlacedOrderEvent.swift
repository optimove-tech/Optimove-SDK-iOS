import Foundation
import OptimoveSDK
import OptimoveCore

class PlacedOrderEvent: OptimoveEvent {
    
    private let cartItems: [CartItem]
    
    init(_ items: [CartItem]) {
        self.cartItems = items
    }
    
    var name: String {
        return "placed_order"
    }
    
    var parameters: [String : Any] {
        var params: [String: Any] = [:]
        var totalPrice = 0.0
        for i in 0..<self.cartItems.count {
            let item = self.cartItems[i]
            params["item_name_\(i)"] = item.name
            params["item_price_\(i)"] = item.price
            params["item_image_\(i)"] = item.image
            totalPrice += item.price
        }
        params["total_price"] = totalPrice
        return params
    }
}
