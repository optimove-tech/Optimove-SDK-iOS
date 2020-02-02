//  Copyright © 2019 Optimove. All rights reserved.

final class PageVisitEvent: OptimoveCoreEvent {

    struct Constants {
        static let name = "set_page_visit"
        struct Key {
            static let pageTitle = "pageTitle"
            static let category = "category"
        }
    }

    let name: String = Constants.name
    let parameters: [String: Any]

    init(title: String?, category: String?) {
        self.parameters = [
            Constants.Key.pageTitle: title,
            Constants.Key.category: category
        ].compactMapValues { $0 }
    }
}
