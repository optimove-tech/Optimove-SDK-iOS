import Foundation

protocol Fetchable {
    func fetch(completion: @escaping ResultBlockWithBool)
}
