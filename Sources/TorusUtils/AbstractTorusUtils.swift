//import BigInt
import CommonSources
import BigInt
import FetchNodeDetails
import Foundation

public protocol AbstractTorusUtils {
    func retrieveShares(endpoints: [String], torusNodePubs: [TorusNodePubModel], indexes: [BigUInt], verifier: String, verifierParams: VerifierParams, idToken: String, extraParams: [String: Codable]) async throws -> TorusKey

    func getPublicAddress(endpoints: [String], torusNodePubs: [TorusNodePubModel], verifier: String, verifierId: String, extendedVerifierId: String?) async throws -> TorusPublicKey
}
