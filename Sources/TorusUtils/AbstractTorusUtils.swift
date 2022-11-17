

import FetchNodeDetails
import Foundation

public protocol AbstractTorusUtils {
    func retrieveShares(torusNodePubs: Array<TorusNodePubModel>, endpoints: Array<String>, verifierIdentifier: String, verifierId: String, idToken: String, extraParams: Data) async throws -> [String: String]

    func getPublicAddress(endpoints: Array<String>, torusNodePubs: Array<TorusNodePubModel>, verifier: String, verifierId: String, isExtended: Bool) async throws -> GetPublicAddressModel
}
