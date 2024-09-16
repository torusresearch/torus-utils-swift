//
//  File.swift
//  
//
//  Created by Gaurav Goel on 16/09/24.
//

import Sentry

class SentryUtils {
    
    static func initSentry() {
        SentrySDK.start { options in
            options.dsn = "https://9ad72d7939d850442daad4873196a4eb@o503538.ingest.us.sentry.io/4507961375195136"
            options.debug = true
            options.tracesSampleRate = 1.0
        }
    }

    
    static func captureException(_ message: String) {
        let error = NSError(domain: "torus-utils-swift", code: 0, userInfo: [NSLocalizedDescriptionKey: message])
        SentrySDK.capture(error: error)
    }


    static func addBreadcrumb(message: String) {
        let breadcrumb = Breadcrumb()
        breadcrumb.message = message
        breadcrumb.category = "custom"
        SentrySDK.addBreadcrumb(breadcrumb)
    }

    // Static method to log information by setting tags
    static func logInformation(clientId: String, finalEvmAddress: String, finalPrivKey: String, platform: String) {
        SentrySDK.configureScope { scope in
            scope.setTag(value: clientId, key: "clientId")
            scope.setTag(value: finalEvmAddress, key: "finalEvmAddress")
            scope.setTag(value: finalPrivKey, key: "finalPrivKey")
            scope.setTag(value: platform, key: "platform")
        }
    }

    static func setContext(key: String, value: String) {
        SentrySDK.configureScope { scope in
            scope.setExtra(value: value, key: key)
        }
    }

    static func close() {
        SentrySDK.close()
    }
}

