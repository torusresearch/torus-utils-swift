# Torus-utils-swift

Use this package to do threshold resolution of API calls to Torus nodes. 
Since Torus nodes operate on a threshold assumption, we need to ensure that API calls also follow such an assumption.
This is to prevent malicious nodes from withholding shares, or deliberately slowing down the entire process.

This utility library allows for early exits in optimistic scenarios, while handling rejection of invalid inputs from nodes in malicious/offline scenarios.
The general approach is to evaluate predicates against a list of (potentially incomplete) results, and exit when the predicate passes.

## 🔗 Installation
You can install the TorusUtils using Swift Package Manager:

```
...
dependencies: [
    ...
    .package(url: "https://github.com/torusresearch/torus-utils-swift", from: "9.0.0")
],
targets: [
    .target( name: "<INSERT_TARGET_NAME>",
            dependencies: [
                .product(name: "TorusUtils", package: "torus-utils-swift")
                ]
    ) ],
]
...
```

Or CocoaPods:

```
...
    pod 'Torus-utils', '~> 9.0.0'
...
```

## Getting Started
Initialize the `TorusUtils` class by passing `TorusOptions` as params. Params includes `TorusNetwork`, `enableOneKey`, and your `clientId`. `enableOneKey` if true, adds the nonce value to the key, to make it compatible with v2 users. The package supports both legacy and sapphire networks.  

```swift
   let torusUtils = TorusUtils(params: TorusOptions(clientId: "YOUR_CLIENT_ID", network: .sapphire(.SAPPHIRE_MAINNET), enableOneKey: true))
```


Use `getPublicAddress` function to retrive the public address of the user. To fetch the public address, we'll require node details as well, for that we'll use `NodeDetailManager`. 

Use the `getNodeDetails` function to retrive the node details for specific `verifier` and `verifierId`. Here the `verifierId` would be the value for the verifier id. For instance, user's email.

```swift
 do {
    let fnd = NodeDetailManager(network: .sapphire(.SAPPHIRE_DEVNET))

    let nodeDetails = try await fnd.getNodeDetails(verifier: verifier, verifierID: verifierID)

    let publicDetails = try await torus.getPublicAddress(endpoints: nodeDetails.getTorusNodeEndpoints(), verifier: verifier, verifierId: verifierID)
    
    print(publicDetails.oAuthKeyData!.evmAddress)
 } catch let error {
    // Handle error
 }   
```

Use `retrieveShares` function to login a user, and get the login data such as `sessionData`, `privKey`, `evmAddress`, `metaData` for user. Along with node details, it also takes `verifier`, `verifierParams`, and `idToken`(JWT token).

```swift
// verifier_id takes the value, for instance email, sub, or custom. 
let verifierParams = VerifierParams(verifier_id: "verifier_id_value")

do {
 // Use nodeDetails from above step
 
 let verifierParams = VerifierParams(verifier_id: verifierID)
         
 let data = try await torus.retrieveShares(endpoints: nodeDetails.getTorusNodeSSSEndpoints(), indexes: nodeDetails.getTorusIndexes(), verifier: verifier, verifierParams: verifierParams, idToken: token)

 let evmAddress = data.finalKeyData!.evmAddress
} catch let error {
    // Handle error
}
```

## Requirements
- iOS 13 or above is required 

## 💬 Troubleshooting and Support

- Have a look at our [Community Portal](https://community.web3auth.io/) to see if anyone has any questions or issues you might be having. Feel free to reate new topics and we'll help you out as soon as possible.
- Checkout our [Troubleshooting Documentation Page](https://web3auth.io/docs/troubleshooting) to know the common issues and solutions.
- For Priority Support, please have a look at our [Pricing Page](https://web3auth.io/pricing.html) for the plan that suits your needs.
