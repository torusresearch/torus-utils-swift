class SomeError<T>: Error {
    let errors: [Error]
    let responses: [T]
    let predicate: String

    init(errors: [Error], responses: [T], predicate: String) {
        self.errors = errors
        self.responses = responses
        self.predicate = predicate
    }

    var message: String? {
        let errorMessages = errors.map { $0.localizedDescription }.joined(separator: ", ")
        let responseCount = responses.count
        let responseJSON = String(describing: responses)
        return "\(localizedDescription). \(errors.count) errors: \(errorMessages) and \(responseCount) responses: \(responseJSON)"
    }

    var localizedDescription: String {
        return "Unable to resolve enough promises."
    }

    var localizedFailureReason: String? {
        return message
    }

    var errorUserInfo: [String: Any] {
        return [:]
    }
}


func capitalizeFirstLetter(_ str: String) -> String {
    return str.prefix(1).uppercased() + str.dropFirst()
}

func Some<K, T>(_ promises: [Promise<K>], _ predicate: @escaping ([K], _ resolved: Bool) -> Promise<T>) -> Promise<T> {
    return Promise { resolve, reject in
        var finishedCount = 0
        var sharedState = false
        var errorArr: [Error?] = Array(repeating: nil, count: promises.count)
        var resultArr: [K?] = Array(repeating: nil, count: promises.count)
        var predicateError: Error?
        
        for (index, promise) in promises.enumerated() {
            promise
                .done { resp in
                    resultArr[index] = resp
                }
                .catch { error in
                    errorArr[index] = error
                }
                .finally {
                    if sharedState { return }
                    
                    predicate(resultArr.compactMap { $0 }, sharedState)
                        .done { data in
                            sharedState = true
                            resolve(data)
                        }
                        .catch { error in
                            predicateError = error
                        }
                        .finally {
                            finishedCount += 1
                            
                            if finishedCount == promises.count {
                                let errors = resultArr.compactMap { $0 }
                                    .compactMap { (z: K) -> String? in
                                        guard let error = (z as? [String: Any])?["error"] as? [String: Any],
                                              let data = error["data"] as? String else {
                                            return nil
                                        }
                                        
                                        if data.hasPrefix("Error occurred while verifying params") {
                                            return capitalizeFirstLetter(data)
                                        } else {
                                            return data
                                        }
                                    }
                                
                                if !errors.isEmpty {
                                    let errorMsg = errors.count > 1 ? "\n\(errors.map { "• \($0)" }.joined(separator: "\n"))" : errors[0]
                                    reject(SomeError.errors(errorMsg))
                                } else {
                                    reject(SomeError.responses(errorArr.compactMap { $0 }, resultArr.compactMap { $0 }))
                                }
                            }
                        }
                }
        }
    }
}
