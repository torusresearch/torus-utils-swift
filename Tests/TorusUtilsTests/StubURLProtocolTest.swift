//
//  File.swift
//
//
//  Created by Michael Lee on 31/10/2021.
//

import FetchNodeDetails
import Foundation
import OSLog
import PromiseKit
import TorusUtils
import XCTest

@available(iOS 13.0, *)
final class StubURLProtocolTests: XCTestCase {
    func testStubURLProtocol() {
        let expectation = XCTestExpectation(description: "retriveShares using stubbed URLSession should work")

        let sessionConfiguration = URLSessionConfiguration.ephemeral
        sessionConfiguration.protocolClasses = [StubURLProtocol.self]
        let urlSession = URLSession(configuration: sessionConfiguration)
        let torusUtils = StubMockTorusUtils(loglevel: .debug, urlSession: urlSession, enableOneKey: false)
        torusUtils.retrieveShares(torusNodePubs:nodePubKeys,endpoints: endpoints, verifierIdentifier: "torus-direct-mock-ios", verifierId: "michael@tor.us", idToken: "eyJhbGciOiJSUzI1NiIsImtpZCI6ImFkZDhjMGVlNjIzOTU0NGFmNTNmOTM3MTJhNTdiMmUyNmY5NDMzNTIiLCJ0eXAiOiJKV1QifQ.eyJpc3MiOiJodHRwczovL2FjY291bnRzLmdvb2dsZS5jb20iLCJhenAiOiI2MzYxOTk0NjUyNDItZmQ3dWp0b3JwdnZ1ZHRzbDN1M2V2OTBuaWplY3RmcW0uYXBwcy5nb29nbGV1c2VyY29udGVudC5jb20iLCJhdWQiOiI2MzYxOTk0NjUyNDItZmQ3dWp0b3JwdnZ1ZHRzbDN1M2V2OTBuaWplY3RmcW0uYXBwcy5nb29nbGV1c2VyY29udGVudC5jb20iLCJzdWIiOiIxMDkxMTE5NTM4NTYwMzE3OTk2MzkiLCJoZCI6InRvci51cyIsImVtYWlsIjoibWljaGFlbEB0b3IudXMiLCJlbWFpbF92ZXJpZmllZCI6dHJ1ZSwiYXRfaGFzaCI6InRUNDhSck1vdGFFbi1UN3dzc2U3QnciLCJub25jZSI6InZSU2tPZWwyQTkiLCJuYW1lIjoiTWljaGFlbCBMZWUiLCJwaWN0dXJlIjoiaHR0cHM6Ly9saDMuZ29vZ2xldXNlcmNvbnRlbnQuY29tL2EvQUFUWEFKd3NCYjk4Z1NZalZObEJCQWhYSmp2cU5PdzJHRFNlVGYwSTZTSmg9czk2LWMiLCJnaXZlbl9uYW1lIjoiTWljaGFlbCIsImZhbWlseV9uYW1lIjoiTGVlIiwibG9jYWxlIjoiZW4iLCJpYXQiOjE2MzQ0NjgyNDksImV4cCI6MTYzNDQ3MTg0OX0.XGu1tm_OqlSrc5BMDMzOrlhxLZo1YnpCUT0_j2U1mQt86nJzf_Hp85JfapZj2QeeUz91H6-Ei8FR1i4ICEfjMcoZOW1Azc89qUNfUgWeyjqZ7wCHSsbHAwabE74RFAS9YAja8_ynUvCARfDEtoqcreNgmbw3ZntzAqpuuNBXYfbr87kMvu_wZ7fWjLKM91CvuXytQBwtieTyjAFnTXmEL60Pdu-JSQfHCbS5H39ZHlnYxEO6qztIjvbnQokhjHDGc4PMCx0wfzrEet1ojNOCnbfmaYE5NQudquzQNZtqZfn8f4B-sQhECElnOXagHlafWO5RayS0dCb1mTfr8orcCA", extraParams: Data(base64Encoded: "YnBsaXN0MDDUAQIDBAUGBwpYJHZlcnNpb25ZJGFyY2hpdmVyVCR0b3BYJG9iamVjdHMSAAGGoF8QD05TS2V5ZWRBcmNoaXZlctEICVRyb290gAGnCwwXGBkaG1UkbnVsbNMNDg8QExZXTlMua2V5c1pOUy5vYmplY3RzViRjbGFzc6IREoACgAOiFBWABIAFgAZfEBJ2ZXJpZmllcmlkZW50aWZpZXJbdmVyaWZpZXJfaWRfEBV0b3J1cy1kaXJlY3QtbW9jay1pb3NebWljaGFlbEB0b3IudXPSHB0eH1okY2xhc3NuYW1lWCRjbGFzc2VzXE5TRGljdGlvbmFyeaIgIVxOU0RpY3Rpb25hcnlYTlNPYmplY3QACAARABoAJAApADIANwBJAEwAUQBTAFsAYQBoAHAAewCCAIUAhwCJAIwAjgCQAJIApwCzAMsA2gDfAOoA8wEAAQMBEAAAAAAAAAIBAAAAAAAAACIAAAAAAAAAAAAAAAAAAAEZ")!).done { data in
            XCTAssertEqual(data["publicAddress"]!, "0x22f2Ce611cE0d0ff4DA661d3a4C4B7A60B2b13F8")
            XCTAssertEqual(data["privateKey"]!, "495b9a126c0c703caeaa5c561692d6778952c455789b0a2ba04312cfdc2e1bb9")
            expectation.fulfill()
        }.catch { err in
            XCTFail(err.localizedDescription)
        }

        wait(for: [expectation], timeout: 12000)
    }
}

public class StubMockTorusUtils: TorusUtils {
    override open func getTimestamp() -> TimeInterval {
        let ret = 0.0
        print("[StubMockTorusUtils] getTimeStamp(): ", ret)
        return ret
    }

    override open func generatePrivateKeyData() -> Data? {
        // empty bytes
        let ret = Data(base64Encoded: "FBz7bssmbsV6jBWoOJpkVOu14+6/Xgyt1pxTycODG08=")

        print("[StubMockTorusUtils] generatePrivateKeyData(): ", ret!.bytes.toBase64())
        return ret
    }
}

let endpoints = ["https://teal-15-1.torusnode.com/jrpc", "https://teal-15-3.torusnode.com/jrpc", "https://teal-15-4.torusnode.com/jrpc", "https://teal-15-5.torusnode.com/jrpc", "https://teal-15-2.torusnode.com/jrpc"]

let nodePubKeys = [TorusNodePubModel(_X: "1363aad8868cacd7f8946c590325cd463106fb3731f08811ab4302d2deae35c3", _Y: "d77eebe5cdf466b475ec892d5b4cffbe0c1670525debbd97eee6dae2f87a7cbe"), TorusNodePubModel(_X: "7c8cc521c48690f016bea593f67f88ad24f447dd6c31bbab541e59e207bf029d", _Y: "b359f0a82608db2e06b953b36d0c9a473a00458117ca32a5b0f4563a7d539636"), TorusNodePubModel(_X: "8a86543ca17df5687719e2549caa024cf17fe0361e119e741eaee668f8dd0a6f", _Y: "9cdb254ff915a76950d6d13d78ef054d5d0dc34e2908c00bb009a6e4da701891"), TorusNodePubModel(_X: "25a98d9ae006aed1d77e81d58be8f67193d13d01a9888e2923841894f4b0bf9c", _Y: "f63d40df480dacf68922004ed36dbab9e2969181b047730a5ce0797fb6958249"), TorusNodePubModel(_X: "d908f41f8e06324a8a7abcf702adb6a273ce3ae63d86a3d22723e1bbf1438c9a", _Y: "f977530b3ec0e525438c72d1e768380cbc5fb3b38a760ee925053b2e169428ce")]
