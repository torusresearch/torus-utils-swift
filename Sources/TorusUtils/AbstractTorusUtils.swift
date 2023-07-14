import FetchNodeDetails
import CommonSources
import Foundation

public protocol AbstractTorusUtils {
    func retrieveShares( endpoints: [String], torusNodePubs: [TorusNodePubModel]?, verifier: String, verifierParams: VerifierParams, idToken: String, extraParams: [String:Codable]) async throws -> RetrieveSharesResponse

    func getPublicAddress(endpoints: [String], torusNodePubs: [TorusNodePubModel]?, verifier: String, verifierId: String, extendedVerifierId :String?) async throws -> TorusPublicKey
}
