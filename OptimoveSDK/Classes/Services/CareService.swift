// Copiright 2019 Optimove

import Foundation

/// The service used to keep clean persistant layer.
/// For example, when unused key going to be deleted, just place this key here in constants and service will delete it
/// on the next run.
final class CareService {

    private let groupStorage: OptimoveCarefullStorage
    private let sharedStorage: OptimoveCarefullStorage

    init(groupStorage: OptimoveCarefullStorage,
         sharedStorage: OptimoveCarefullStorage) {
        self.groupStorage = groupStorage
        self.sharedStorage = sharedStorage
    }

    func makeSomeCare() {
        let groupKeys: [String] = [
            // Add an group key here.
        ]
        groupKeys.forEach { (key) in
            groupStorage.removeValue(forKey: key)
        }
        var sharedKeys: [String] = [
            // Add an shared key here.
        ]
        sharedKeys = sharedKeys + MbaasOperation.allCases.map { "\($0.rawValue)_endpoint" }
        sharedKeys.forEach { (key) in
            sharedStorage.removeValue(forKey: key)
        }
    }

}
