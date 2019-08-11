import Foundation

struct RealtimeMetaData: Codable, MetaData {
    var realtimeToken: String
    var realtimeGateway: URL
}
