import Foundation

struct OptimoveEventConfig:Decodable
{
    let id: Int
    let supportedOnOptitrack: Bool
    let supportedOnRealTime: Bool
    let parameters: [String:Parameter]
}
