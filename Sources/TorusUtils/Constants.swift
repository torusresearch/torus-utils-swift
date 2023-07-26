enum JRPC_METHODS  {
    static let GET_OR_SET_KEY = "GetPubKeyOrKeyAssign"
    static let COMMITMENT_REQUEST = "CommitmentRequest"
    static let IMPORT_SHARE = "ImportShare"
    static let GET_SHARE_OR_KEY_ASSIGN = "GetShareOrKeyAssign"
    static let LEGACY_VERIFIER_LOOKUP_REQUEST = "VerifierLookupRequest"
    static let LEGACY_KEY_ASSIGN = "KeyAssign"
    static let LEGACY_SHARE_REQUEST = "ShareRequest"
}

let CURVE_N: String = "FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141"

let LEGACY_METADATA_HOST = "https://metadata.tor.us"
