import Foundation

internal enum httpMethod {
    case get
    case post

    var name: String {
        switch self {
        case .get:
            return "GET"
        case .post:
            return "POST"
        }
    }
}
