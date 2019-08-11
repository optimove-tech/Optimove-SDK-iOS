import Foundation

struct OptitrackMetadata: Decodable {
    var eventCategoryName: String
    var eventIdCustomDimensionId: Int
    var eventNameCustomDimensionId: Int
    var optitrackEndpoint: String
    var siteId: Int

    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)

        self.eventCategoryName = try values.decode(String.self, forKey: .eventCategoryName)
        self.eventIdCustomDimensionId = try values.decode(Int.self, forKey: .eventIdCustomDimensionId)
        self.eventNameCustomDimensionId = try values.decode(Int.self, forKey: .eventNameCustomDimensionId)
        self.siteId = try values.decode(Int.self, forKey: .siteId)
        let trackPath = try values.decode(String.self, forKey: .optitrackEndpoint)
        if trackPath.contains("/piwik.php") {
            self.optitrackEndpoint = trackPath
        } else {
            self.optitrackEndpoint = (trackPath.last! == "/") ? "\(trackPath)piwik.php" : "\(trackPath)/piwik.php"
        }
    }

    enum CodingKeys: String, CodingKey {
        case eventCategoryName
        case eventIdCustomDimensionId
        case eventNameCustomDimensionId
        case optitrackEndpoint
        case siteId
    }
}
