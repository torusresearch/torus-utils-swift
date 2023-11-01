import Foundation

enum HTTPMethod {
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

extension TorusUtils {
    func createURLSession() -> URLSession {
        let session = URLSession(configuration: urlSession.configuration)
        return session
    }
}
