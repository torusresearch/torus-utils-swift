import FetchNodeDetails
import Foundation

public protocol AbstractTorusUtils {
    func retrieveShares( endpoints: [String], verifier: String, verifierId: String, verifierParams: VerifierParams, idToken: String, extraParams: Data) async throws -> RetrieveSharesResponse

    func getPublicAddress(endpoints: [String], verifier: String, verifierId: String, extendedVerifierId :String?, isExtended: Bool) async throws -> GetPublicAddressResult
}
