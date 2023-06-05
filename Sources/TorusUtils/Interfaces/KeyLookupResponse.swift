import Foundation

public struct KeyLookupResponse: CustomStringConvertible, Hashable {

    public let pubKeyX: String
    public let pubKeyY: String
    public let keyIndex: String
    public let address: String
    public var description: String {
        return "public key X is \(pubKeyX) public key Y is \(pubKeyY) address is \(address)"
    }

    public init(pubKeyX: String, pubKeyY: String, keyIndex: String, address: String) {
        self.pubKeyX = pubKeyX
        self.pubKeyY = pubKeyY
        self.keyIndex = keyIndex
        self.address = address
    }

}

public enum KeyLookupError: Error {
    case verifierNotSupported
    case verifierAndVerifierIdNotAssigned
    case configError

    static func createErrorFromString(errorString: String) -> Self {
        if errorString.contains("Verifier not supported") {
            return .verifierNotSupported
        } else if errorString.contains("Verifier + VerifierID has not yet been assigned") {
            return .verifierAndVerifierIdNotAssigned
        } else {
            return .configError
        }
    }
}

extension KeyLookupError: LocalizedError {

    public var errorDescription: String? {
        switch self {
        case .verifierNotSupported:
            return "Verifier not supported. Check if you: \n1. Are on the right network (Torus testnet/mainnet) \n2. Have setup a verifier on dashboterard.web3auth.io?"
        case .verifierAndVerifierIdNotAssigned:
            return "Verifier + VerifierID has not yet been assigned"
        case .configError:
            return "ConfigurationError"
        }
    }
}
