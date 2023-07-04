import FetchNodeDetails
import Foundation

public protocol AbstractTorusUtils {
    func retrieveShares( endpoints: [String], verifier: String, verifierParams: VerifierParams, idToken: String, extraParams: [String:Any]) async throws -> RetrieveSharesResponse

    func getPublicAddress(endpoints: [String], verifier: String, verifierId: String, extendedVerifierId :String?) async throws -> String
}
