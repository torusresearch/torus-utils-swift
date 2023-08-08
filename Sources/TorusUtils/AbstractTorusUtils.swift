import FetchNodeDetails
import Foundation

public protocol AbstractTorusUtils {
    func retrieveShares(torusNodePubs: [TorusNodePubModel], endpoints: [String], verifier: String, verifierId: String, idToken: String, extraParams: Data) async throws -> RetrieveSharesResponseModel

    func getPublicAddress(endpoints: [String], torusNodePubs: [TorusNodePubModel], verifier: String, verifierId: String, isExtended: Bool) async throws -> GetPublicAddressModel
    
    func getPostBoxKey(torusKey: RetrieveSharesResponseModel) -> String
}
