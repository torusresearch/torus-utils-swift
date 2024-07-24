import Foundation

public class PubNonce: Codable, Equatable {
    public static func == (lhs: PubNonce, rhs: PubNonce) -> Bool {
        return lhs.x == rhs.x && lhs.y == rhs.y
    }

    public var x: String
    public var y: String

    internal init(x: String, y: String) {
        self.x = x
        self.y = y
    }

    public required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        x = try container.decode(String.self, forKey: .x)
        y = try container.decode(String.self, forKey: .y)
    }
}
