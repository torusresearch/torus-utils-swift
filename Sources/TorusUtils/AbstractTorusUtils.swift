

import FetchNodeDetails
import Foundation
import PromiseKit

public protocol AbstractTorusUtils {
    func retrieveShares(torusNodePubs: Array<TorusNodePubModel>, endpoints: Array<String>, verifierIdentifier: String, verifierId: String, idToken: String, extraParams: Data) -> Promise<[String: String]>

    func getPublicAddress(endpoints: Array<String>, torusNodePubs: Array<TorusNodePubModel>, verifier: String, verifierId: String, isExtended: Bool) -> Promise<GetPublicAddressModel>
}
