import XCTest
import PromiseKit
import fetch_node_details
import CryptoSwift
import web3swift
import secp256k1

@testable import torus_utils_swift

final class torus_utils_swiftTests: XCTestCase {
    
    static let context = secp256k1_context_create(UInt32(SECP256K1_CONTEXT_SIGN|SECP256K1_CONTEXT_VERIFY))

    var tempVerifierId = "shubham@tor.us"
    
    func testKeyLookup() {
        
        let expectation = self.expectation(description: "getting node details")
        
        let fd = Torus()
        let arr = ["https://lrc-test-13-a.torusnode.com/jrpc", "https://lrc-test-13-b.torusnode.com/jrpc", "https://lrc-test-13-c.torusnode.com/jrpc", "https://lrc-test-13-d.torusnode.com/jrpc", "https://lrc-test-13-e.torusnode.com/jrpc"]
        let key = fd.keyLookup(endpoints: arr, verifier: "google", verifierId: "somethinsdfgTest@g.com")
        key.done { data in
            print(data)
            expectation.fulfill()
        }
        
        waitForExpectations(timeout: 6)
    }
    
    func testKeyAssign(){
        let expectations = self.expectation(description: "testing key assign")
        let fd = Torus()
        
        let nodePubKeys : Array<TorusNodePub> = [TorusNodePub(_X: "4086d123bd8b370db29e84604cd54fa9f1aeb544dba1cc9ff7c856f41b5bf269", _Y: "fde2ac475d8d2796aab2dea7426bc57571c26acad4f141463c036c9df3a8b8e8"),TorusNodePub(_X: "1d6ae1e674fdc1849e8d6dacf193daa97c5d484251aa9f82ff740f8277ee8b7d", _Y: "43095ae6101b2e04fa187e3a3eb7fbe1de706062157f9561b1ff07fe924a9528"),TorusNodePub(_X: "fd2af691fe4289ffbcb30885737a34d8f3f1113cbf71d48968da84cab7d0c262", _Y: "c37097edc6d6323142e0f310f0c2fb33766dbe10d07693d73d5d490c1891b8dc"),TorusNodePub(_X: "e078195f5fd6f58977531135317a0f8d3af6d3b893be9762f433686f782bec58", _Y: "843f87df076c26bf5d4d66120770a0aecf0f5667d38aa1ec518383d50fa0fb88"),TorusNodePub(_X: "a127de58df2e7a612fd256c42b57bb311ce41fd5d0ab58e6426fbf82c72e742f", _Y: "388842e57a4df814daef7dceb2065543dd5727f0ee7b40d527f36f905013fa96")
        ]
        
        let keyAssign = fd.keyAssign(endpoints: ["https://lrc-test-13-a.torusnode.com/jrpc", "https://lrc-test-13-b.torusnode.com/jrpc", "https://lrc-test-13-c.torusnode.com/jrpc", "https://lrc-test-13-d.torusnode.com/jrpc", "https://lrc-test-13-e.torusnode.com/jrpc"], torusNodePubs: nodePubKeys, verifier: "google", verifierId: self.tempVerifierId)
        
        print(keyAssign)
        keyAssign.done{ data in
            print("data", data.result)
            expectations.fulfill()
        }.catch{ err in
            print("keyAssign failed", err)
        }
        waitForExpectations(timeout: 20)
    }
    
    func testingPromise() {
        testingAnotherrPromise().then{ data -> Promise<String> in
            print(data, "ASqweqd")
            return Promise<String>.value("this is a randomValue")
        }
    }
    
    func testingAnotherrPromise()-> Promise<String>{
        let (tempPromise, seal) = Promise<String>.pending()
        
        seal.fulfill("ASDF")
        tempPromise.then{ data -> Promise<String> in
            print("ASDF", data)
            return Promise<String>.value(data + "qweqwe")
        }
        return tempPromise
        print(tempPromise)
    }
    
    func testGetPublicAddress(){
        let expectations = self.expectation(description: "testing get public address")
        let fd = Torus()
        
        let nodePubKeys : Array<TorusNodePub> = [TorusNodePub(_X: "4086d123bd8b370db29e84604cd54fa9f1aeb544dba1cc9ff7c856f41b5bf269", _Y: "fde2ac475d8d2796aab2dea7426bc57571c26acad4f141463c036c9df3a8b8e8"),TorusNodePub(_X: "1d6ae1e674fdc1849e8d6dacf193daa97c5d484251aa9f82ff740f8277ee8b7d", _Y: "43095ae6101b2e04fa187e3a3eb7fbe1de706062157f9561b1ff07fe924a9528"),TorusNodePub(_X: "fd2af691fe4289ffbcb30885737a34d8f3f1113cbf71d48968da84cab7d0c262", _Y: "c37097edc6d6323142e0f310f0c2fb33766dbe10d07693d73d5d490c1891b8dc"),TorusNodePub(_X: "e078195f5fd6f58977531135317a0f8d3af6d3b893be9762f433686f782bec58", _Y: "843f87df076c26bf5d4d66120770a0aecf0f5667d38aa1ec518383d50fa0fb88"),TorusNodePub(_X: "a127de58df2e7a612fd256c42b57bb311ce41fd5d0ab58e6426fbf82c72e742f", _Y: "388842e57a4df814daef7dceb2065543dd5727f0ee7b40d527f36f905013fa96")
        ]
        
        let getpublicaddress = fd.getPublicAddress(endpoints: ["https://lrc-test-13-a.torusnode.com/jrpc", "https://lrc-test-13-b.torusnode.com/jrpc", "https://lrc-test-13-c.torusnode.com/jrpc", "https://lrc-test-13-d.torusnode.com/jrpc", "https://lrc-test-13-e.torusnode.com/jrpc"], torusNodePubs: nodePubKeys, verifier: "google", verifierId: tempVerifierId, isExtended: true)
        
        print(getpublicaddress)
        getpublicaddress.done{ data in
            print("data", data)
            expectations.fulfill()
        }.catch{ err in
            print("getpublicaddress failed", err)
        }
        waitForExpectations(timeout: 10)
    }
    
    func testretreiveShares(){
        let expectations = self.expectation(description: "testing get public address")
        let fd = Torus()
        let verifierParams = ["verifier_id": tempVerifierId]
        let token = "eyJhbGciOiJSUzI1NiIsImtpZCI6IjI1N2Y2YTU4MjhkMWU0YTNhNmEwM2ZjZDFhMjQ2MWRiOTU5M2U2MjQiLCJ0eXAiOiJKV1QifQ.eyJpc3MiOiJodHRwczovL2FjY291bnRzLmdvb2dsZS5jb20iLCJhenAiOiI4NzY3MzMxMDUxMTYtaTBoajNzNTNxaWlvNWs5NXBycGZtajBocDBnbWd0b3IuYXBwcy5nb29nbGV1c2VyY29udGVudC5jb20iLCJhdWQiOiI4NzY3MzMxMDUxMTYtaTBoajNzNTNxaWlvNWs5NXBycGZtajBocDBnbWd0b3IuYXBwcy5nb29nbGV1c2VyY29udGVudC5jb20iLCJzdWIiOiIxMDk1ODQzNTA5MTA3Mjc0NzAzNDkiLCJoZCI6InRvci51cyIsImVtYWlsIjoic2h1YmhhbUB0b3IudXMiLCJlbWFpbF92ZXJpZmllZCI6dHJ1ZSwiYXRfaGFzaCI6InZYZnFYLVd6ZW8tdURBV19EUTNoYnciLCJub25jZSI6IlVJMHplalpvb1BhZDZHc1dOM0VGV2dsS1RRZWZjeiIsIm5hbWUiOiJTaHViaGFtIFJhdGhpIiwicGljdHVyZSI6Imh0dHBzOi8vbGg0Lmdvb2dsZXVzZXJjb250ZW50LmNvbS8tT19SUi1aYlQwZVUvQUFBQUFBQUFBQUkvQUFBQUFBQUFBQUEvQUFLV0pKTmVleHhiRHozcjFVVnBrWjVGbzdsYTNhMXZRZy9zOTYtYy9waG90by5qcGciLCJnaXZlbl9uYW1lIjoiU2h1YmhhbSIsImZhbWlseV9uYW1lIjoiUmF0aGkiLCJsb2NhbGUiOiJlbiIsImlhdCI6MTU4NTg5ODc5NiwiZXhwIjoxNTg1OTAyMzk2LCJqdGkiOiI0ODJkNmYxZTk1MzhhMmMzZjdjNjc3MTM2ZTI5MjNhM2I4YzM1OWJkIn0.XrX14yae1qJunwp8pDSGrdkkTuXKV539XSQYFNT9_DWd0GchXEZsO81Az-P1m88GzMHzw9wo6AbIti8phUNa2MwEqUrS5WYxt1QrPgoAVv6HI56aMbK04HX92yO5uh36y8S_gmxjTW5O9rYsAJv0UEP3uNrcq_TmL9Y3TAaHEnk2qcipNxMT9kjaQwU0B6jIjnOKqZenF06y-QOjzyt4TwRH0T9oEymit-iq_83Alks8FirTpsKNhTHSnLIOdlxHGYYGv1EyWPNiA6lNz5f_OVxsisTOknzfUthma6BVJV4yIfBj2gbmxGK5pMJsjKcI4ELmRlzhO8aCCKvNwwQMlQ"
        
        let nodePubKeys : Array<TorusNodePub> = [TorusNodePub(_X: "4086d123bd8b370db29e84604cd54fa9f1aeb544dba1cc9ff7c856f41b5bf269", _Y: "fde2ac475d8d2796aab2dea7426bc57571c26acad4f141463c036c9df3a8b8e8"),TorusNodePub(_X: "1d6ae1e674fdc1849e8d6dacf193daa97c5d484251aa9f82ff740f8277ee8b7d", _Y: "43095ae6101b2e04fa187e3a3eb7fbe1de706062157f9561b1ff07fe924a9528"),TorusNodePub(_X: "fd2af691fe4289ffbcb30885737a34d8f3f1113cbf71d48968da84cab7d0c262", _Y: "c37097edc6d6323142e0f310f0c2fb33766dbe10d07693d73d5d490c1891b8dc"),TorusNodePub(_X: "e078195f5fd6f58977531135317a0f8d3af6d3b893be9762f433686f782bec58", _Y: "843f87df076c26bf5d4d66120770a0aecf0f5667d38aa1ec518383d50fa0fb88"),TorusNodePub(_X: "a127de58df2e7a612fd256c42b57bb311ce41fd5d0ab58e6426fbf82c72e742f", _Y: "388842e57a4df814daef7dceb2065543dd5727f0ee7b40d527f36f905013fa96")
        ]
        
        let retreiveShares = fd.retreiveShares(endpoints: ["https://lrc-test-13-a.torusnode.com/jrpc", "https://lrc-test-13-b.torusnode.com/jrpc", "https://lrc-test-13-c.torusnode.com/jrpc", "https://lrc-test-13-d.torusnode.com/jrpc", "https://lrc-test-13-e.torusnode.com/jrpc"], verifier: "google", verifierParams: verifierParams, idToken: token)
        //
        //        print(getpublicaddress)
        //        getpublicaddress.done{ data in
        //            print("data", data)
        //            expectations.fulfill()
        //        }.catch{ err in
        //            print("getpublicaddress failed", err)
        //        }
        waitForExpectations(timeout: 10)
    }
    
    func testdecodeShares(){
        
        // privatekey 1e75e044afdaf4509e46d8d9907439d75e263fc2baffe597a7f31e94c0fc7e05
        //
        //        JSONRPCresponse(id: 10, jsonrpc: "2.0", result: Optional(["keys": [["PublicKey": ["X": "bc5b761516115b97c9fde7d763e8f78694bcaca245020db064adfaca79a2281f", "Y": "59f673821f9885e1cc53b6c3e80e802900dd4cbdd663dc97f9e3f83f55bbd768"], "Index": "5", "Threshold": 1, "Share": "ZmM5MzMxMDZmYzEzYWQ5YzVlOWQyYzM2NzhkODE3MGJiZjJhZTkwOTQ4ZWY1OTc5Y2YwZTQyYjFhMjRmZmE1MzI2YmI4NmEzNWEyYzJkNGIzOTFmMTlmYmEzMDY0NGU4", "Verifiers": ["google": ["shubham@tor.us"]], "Metadata": ["ephemPublicKey": "04a4abdc1e2adf241d444ec328059989dea9ed5498384e1040324cc748653df20db3da34d4607bfd0b1ca3f1e52666cb169b9766466c76a0b2c8373b070997637a", "mac": "7fbb4ee8902f87d5029260eea0d133c0e86998e3c5218236d23557fdfc6eaa30", "mode": "AES256", "iv": "d0940684def51afbfeea3b1892d6e8a6"]]]]), error: nil, message: nil)
        //        JSONRPCresponse(id: 10, jsonrpc: "2.0", result: Optional(["keys": [["Share": "NTg4MTQ0ZjA4MjBlYjVmNzMzZWViYzE0NjZjOGRlOTA3YTNmZjk3OTgzYTVmOGNhMjQ5OGZhNTIyYWY1NmY3NDlkNWMxOWViODU1ZmQzNGJkNzZmMTE4MGVlNTY5YWMz", "Verifiers": ["google": ["shubham@tor.us"]], "Index": "5", "Threshold": 1, "PublicKey": ["X": "bc5b761516115b97c9fde7d763e8f78694bcaca245020db064adfaca79a2281f", "Y": "59f673821f9885e1cc53b6c3e80e802900dd4cbdd663dc97f9e3f83f55bbd768"], "Metadata": ["iv": "9ceb3a578077a9cbaf4e0746d495b643", "mode": "AES256", "mac": "a5cc337209d4ee6a884e512f18c7a493bbbac23a7a21e45ab264f3b140fc9635", "ephemPublicKey": "04de153e0a02153f3d8e9d36d17915261b96e7763de254ede5e03868f1ac1cbc394f30f2f7ba5bd266c6c6f925bcfe3b3fe7fa6571de29ae402bd77cfbe9ec9fc7"]]]]), error: nil, message: nil)
        //        JSONRPCresponse(id: 10, jsonrpc: "2.0", result: Optional(["keys": [["Share": "ODQ3ZDRkMmJlMGViMzYyZjdhYTZhYjYyMTAzYWUwMzkyMzYzZTgxZDQzZTdlMTUxY2ViM2ZkZWQzZDI1NWE4Njc0ZjI2ODYyODE5YmVlMWQzNjEwMTE5OTI2NGE0Njc4", "PublicKey": ["X": "bc5b761516115b97c9fde7d763e8f78694bcaca245020db064adfaca79a2281f", "Y": "59f673821f9885e1cc53b6c3e80e802900dd4cbdd663dc97f9e3f83f55bbd768"], "Metadata": ["mode": "AES256", "iv": "2956ef4b3d8a497ca2b6bf8af4d242f5", "mac": "65d5904eab0b3cad436c48aa908bbfa6ff49439fc545f93782047729b3aa272f", "ephemPublicKey": "04a300f00e443049608e364a84a313b1d97d48bb60feff11f5e6026d174b11ec12a936f5c8ad08f16a7d748c942240b863077e6d261b683dc15064c7c73db9e7ad"], "Index": "5", "Verifiers": ["google": ["shubham@tor.us"]], "Threshold": 1]]]), error: nil, message: nil)
        
        let iv1 = "d0940684def51afbfeea3b1892d6e8a6".hexa
        let share1 = "fc933106fc13ad9c5e9d2c3678d8170bbf2ae90948ef5979cf0e42b1a24ffa5326bb86a35a2c2d4b391f19fba30644e8".hexa
        
        
        let key1 = "1e75e044afdaf4509e46d8d9907439d75e263fc2baffe597a7f31e94c0fc7e05".hexa
        // print(share1)
        
        do{

            let aes = try! AES(key: key1, blockMode: CBC(iv: iv1), padding: .pkcs7)
            let encrypt = try! aes.encrypt(share1)
            print("encrypt", encrypt.hexa)


            let decrypt = try! aes.decrypt(share1)
            print("decrypt", decrypt)

        }catch CryptoSwift.AES.Error.dataPaddingRequired{
            print("padding error")
        }
    }
    
    func privateKeyToPublicKey4(privateKey: Data) -> secp256k1_pubkey? {
        if (privateKey.count != 32) {return nil}
        var publicKey = secp256k1_pubkey()
        let result = privateKey.withUnsafeBytes { (a: UnsafeRawBufferPointer) -> Int32? in
            if let pkRawPointer = a.baseAddress, a.count > 0 {
                let privateKeyPointer = pkRawPointer.assumingMemoryBound(to: UInt8.self)
                let res = secp256k1_ec_pubkey_create(torus_utils_swiftTests.context!, UnsafeMutablePointer<secp256k1_pubkey>(&publicKey), privateKeyPointer)
                return res
            } else {
                return nil
            }
        }
        guard let res = result, res != 0 else {
            return nil
        }
        return publicKey
    }
    
    func ecdh(pubKey: secp256k1_pubkey, privateKey: Data) -> secp256k1_pubkey? {
        var pubKey2 = pubKey
        if (privateKey.count != 32) {return nil}
        let result = privateKey.withUnsafeBytes { (a: UnsafeRawBufferPointer) -> Int32? in
            if let pkRawPointer = a.baseAddress, a.count > 0 {
                let privateKeyPointer = pkRawPointer.assumingMemoryBound(to: UInt8.self)
                let res = secp256k1_ec_pubkey_tweak_mul(torus_utils_swiftTests.context!, UnsafeMutablePointer<secp256k1_pubkey>(&pubKey2), privateKeyPointer)
                return res
            } else {
                return nil
            }
        }
        guard let res = result, res != 0 else {
            return nil
        }
        return pubKey2
    }
    
    func testECDH() {
        
        // print(array32toTuple("a4abdc1e2adf241d444ec328059989dea9ed5498384e1040324cc748653df20db3da34d4607bfd0b1ca3f1e52666cb169b9766466c76a0b2c8373b070997637a".hexa))
        
        var testArr = "a300f00e443049608e364a84a313b1d97d48bb60feff11f5e6026d174b11ec12a936f5c8ad08f16a7d748c942240b863077e6d261b683dc15064c7c73db9e7ad".hexa
        var newtest = testArr.prefix(32)
        newtest.reverse()
//        print(newtest)

        var newTest2 = testArr.suffix(32)
        newTest2.reverse()

        newtest.append(contentsOf: newTest2)
        //print(newtest)
        
        
        var ephemPubKey = secp256k1_pubkey.init(data: array32toTuple(Array(newtest)))
        var sharedSecret = ecdh(pubKey: ephemPubKey, privateKey: Data.init(hexString: "1e75e044afdaf4509e46d8d9907439d75e263fc2baffe597a7f31e94c0fc7e05")!)
        var sharedSecretData = sharedSecret!.data
        var sharedSecretPrefix = tupleToArray(sharedSecretData).prefix(32)
        var reversedSharedSecret = sharedSecretPrefix.reversed()
        print(reversedSharedSecret.hexa)
//        print(tupleToArray(sharedSecretData).)
        
        // let prefix = sharedSecretData.prefix(32)
//        print("sharedSecretData", sharedSecretData)
        var newXValue = reversedSharedSecret.hexa
        
        
        var hash = SHA2(variant: .sha512).calculate(for: newXValue.hexa).hexa
        let AesEncryptionKey = hash.prefix(64)
        let iv1 = "2956ef4b3d8a497ca2b6bf8af4d242f5".hexa
        let share1 = "ODQ3ZDRkMmJlMGViMzYyZjdhYTZhYjYyMTAzYWUwMzkyMzYzZTgxZDQzZTdlMTUxY2ViM2ZkZWQzZDI1NWE4Njc0ZjI2ODYyODE5YmVlMWQzNjEwMTE5OTI2NGE0Njc4".fromBase64()!.hexa
        // print("hash", hash)

        do{
            let aes = try! AES(key: AesEncryptionKey.hexa, blockMode: CBC(iv: iv1), padding: .pkcs7)
              //let encrypt = try! aes.encrypt(share1)
              // print("encrypt", encrypt.hexa)


            let decrypt = try! aes.decrypt(share1)
            print("decrypt", decrypt.hexa)

        }catch CryptoSwift.AES.Error.dataPaddingRequired{
            print("padding error")
        }
        // print(sharedSecret, tupleToArray(sharedSecretData).hexa)
    }
    
    func testLagrangeInterpolation(){
        // Share1 0b2334aa653297de5ec3e3ff404861f8b495da6daeb82a3f471323acf016c652
        // Share2 9948c1666b858b7d675af89be0e5dc494469fc8ae41eff20a7ad35829cd7d1c1
        // Share3 ff040f695709486ac6d1db488e26e53a59596670ecf349f86f8170eb9ef43579
        
        let shareList = [1:"0b2334aa653297de5ec3e3ff404861f8b495da6daeb82a3f471323acf016c652", 2:"9948c1666b858b7d675af89be0e5dc494469fc8ae41eff20a7ad35829cd7d1c1", 3:"ff040f695709486ac6d1db488e26e53a59596670ecf349f86f8170eb9ef43579"]
        
        
    }
    
    func tupleToArray(_ tuple: Any) -> [UInt8] {
        // var result = [UInt8]()
        let tupleMirror = Mirror(reflecting: tuple)
        let tupleElements = tupleMirror.children.map({ $0.value as! UInt8 })
        return tupleElements
    }
    
    func array32toTuple(_ arr: Array<UInt8>) -> (UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8){
        return (arr[0] as UInt8, arr[1] as UInt8, arr[2] as UInt8, arr[3] as UInt8, arr[4] as UInt8, arr[5] as UInt8, arr[6] as UInt8, arr[7] as UInt8, arr[8] as UInt8, arr[9] as UInt8, arr[10] as UInt8, arr[11] as UInt8, arr[12] as UInt8, arr[13] as UInt8, arr[14] as UInt8, arr[15] as UInt8, arr[16] as UInt8, arr[17] as UInt8, arr[18] as UInt8, arr[19] as UInt8, arr[20] as UInt8, arr[21] as UInt8, arr[22] as UInt8, arr[23] as UInt8, arr[24] as UInt8, arr[25] as UInt8, arr[26] as UInt8, arr[27] as UInt8, arr[28] as UInt8, arr[29] as UInt8, arr[30] as UInt8, arr[31] as UInt8, arr[32] as UInt8, arr[33] as UInt8, arr[34] as UInt8, arr[35] as UInt8, arr[36] as UInt8, arr[37] as UInt8, arr[38] as UInt8, arr[39] as UInt8, arr[40] as UInt8, arr[41] as UInt8, arr[42] as UInt8, arr[43] as UInt8, arr[44] as UInt8, arr[45] as UInt8, arr[46] as UInt8, arr[47] as UInt8, arr[48] as UInt8, arr[49] as UInt8, arr[50] as UInt8, arr[51] as UInt8, arr[52] as UInt8, arr[53] as UInt8, arr[54] as UInt8, arr[55] as UInt8, arr[56] as UInt8, arr[57] as UInt8, arr[58] as UInt8, arr[59] as UInt8, arr[60] as UInt8, arr[61] as UInt8, arr[62] as UInt8, arr[63] as UInt8)
    }
    
    static var allTests = [
        ("testretreiveShares", testretreiveShares),
        ("testingPromise", testingPromise),
        ("testECDH", testECDH),
        ("testdecodeShares", testdecodeShares),
        //        ("testKeyLookup", testKeyLookup),
        //        ("testKeyAssign", testKeyAssign),
        ("testGetPublicAddress", testGetPublicAddress)
    ]
}

extension StringProtocol {
    var hexa: [UInt8] {
        var startIndex = self.startIndex
        //print(startIndex, count)
        return (0..<count/2).compactMap { _ in
            let endIndex = index(after: startIndex)
            defer { startIndex = index(after: endIndex) }
            // print(startIndex, endIndex)
            return UInt8(self[startIndex...endIndex], radix: 16)
        }
    }
}

extension Sequence where Element == UInt8 {
    var data: Data { .init(self) }
    var hexa: String { map { .init(format: "%02x", $0) }.joined() }
}

extension Data {
    init?(hexString: String) {
        let length = hexString.count / 2
        var data = Data(capacity: length)
        for i in 0 ..< length {
            let j = hexString.index(hexString.startIndex, offsetBy: i * 2)
            let k = hexString.index(j, offsetBy: 2)
            let bytes = hexString[j..<k]
            if var byte = UInt8(bytes, radix: 16) {
                data.append(&byte, count: 1)
            } else {
                return nil
            }
        }
        self = data
    }
}

extension String {
        func fromBase64() -> String? {
                guard let data = Data(base64Encoded: self) else {
                        return nil
                }
                return String(data: data, encoding: .utf8)
        }
        func toBase64() -> String {
                return Data(self.utf8).base64EncodedString()
        }
}
