import Foundation

struct OptimoveConfigForExtension: Decodable {
    let optitrackMetaData: OptitrackMetadata
    let events: [String: OptimoveEventConfig]
}
