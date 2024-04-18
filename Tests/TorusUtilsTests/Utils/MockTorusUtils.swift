import BigInt
#if canImport(CommonSources)
    import CommonSources
#endif
import FetchNodeDetails
import Foundation
import TorusUtils

class MockTorusUtils: AbstractTorusUtils {
    func retrieveShares(endpoints: [String], torusNodePubs: [TorusNodePubModel], indexes: [BigUInt], verifier: String, verifierParams: VerifierParams, idToken: String, extraParams: [String: Codable]) async throws -> TorusKey {
        return TorusKey(finalKeyData: nil, oAuthKeyData: nil, sessionData: nil, metadata: nil, nodesData: nil)
    }

    func getPublicAddress(endpoints: [String], torusNodePubs: [TorusNodePubModel], verifier: String, verifierId: String, extendedVerifierId: String?) async throws -> TorusPublicKey {
//        GetPublicAddressResult(address: "")
        return TorusPublicKey(finalKeyData: nil, oAuthKeyData: nil, metadata: nil, nodesData: nil)
    }

    var nodePubKeys: [TorusNodePubModel]

    init() {
        nodePubKeys = []
    }

    func setTorusNodePubKeys(nodePubKeys: [TorusNodePubModel]) {
        self.nodePubKeys = nodePubKeys
    }

    func retrieveShares(torusNodePubs: [TorusNodePubModel], endpoints: [String], verifier: String, verifierId: String, idToken: String, extraParams: Data) async throws -> RetrieveSharesResponseModel {
        return .init(publicKey: "", privateKey: "")
    }

    func getPublicAddress(endpoints: [String], torusNodePubs: [TorusNodePubModel], verifier: String, verifierId: String, isExtended: Bool) async throws -> GetPublicAddressResult {
        return .init(address: "")
    }

    func getUserTypeAndAddress(endpoints: [String], torusNodePub: [TorusNodePubModel], verifier: String, verifierID: String, doesKeyAssign: Bool) async throws -> GetUserAndAddress {
        return .init(typeOfUser: .v1, address: "", x: "", y: "")
    }

    func getOrSetNonce(x: String, y: String, privateKey: String?, getOnly: Bool) async throws -> GetOrSetNonceResult {
        return GetOrSetNonceResult(typeOfUser: "v1")
    }
}
