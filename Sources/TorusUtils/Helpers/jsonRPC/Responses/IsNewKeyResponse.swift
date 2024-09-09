import Foundation

internal struct IsNewKeyResponse: Codable {
    public var isNewKey: Bool;
    public var publicKeyX: String;

    public init(isNewKey: Bool, publicKeyX: String) {
        self.isNewKey = isNewKey
        self.publicKeyX = publicKeyX
    }
}
