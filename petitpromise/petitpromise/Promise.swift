//
//  Promise.swift
//  petitpromise
//
//  Created by Reid van Melle on 2017-03-10.
//  Copyright © 2017 rvanmelle. All rights reserved.
//

import Foundation

/**
 https://www.promisejs.org/patterns/
*/

class Promise<T> {

    typealias ResolveCallback = ((T) -> Void)
    typealias ErrorCallback = ((Error) -> Void)
    typealias PromiseCallback = ( ( @escaping ResolveCallback, @escaping ErrorCallback ) throws -> Void )

    internal var fn: PromiseCallback?
    private var result: T?
    private var error: Error?

    private let queue = DispatchQueue( label: "com.petitpromise.serialQueue" )

    init(_ fn: @escaping PromiseCallback) {
        DispatchQueue.main.async {
            do {
                try fn(self.fulfill, self.reject)
            } catch {
                self.reject(err: error)
            }
        }
    }

    private var successResolutions: [ResolveCallback] = []
    private var errorResolutions: [ErrorCallback] = []

    // called by an async function when it obtains a result
    // result is passed onto all waiting functions
    private func fulfill(result:T) {
        queue.async {
            self.result = result
            DispatchQueue.main.async {
                for fn in self.successResolutions {
                    fn(result)
                }
                self.successResolutions = []
            }
        }
    }

    private func reject(err:Error) {
        queue.async {
            self.error = err
            DispatchQueue.main.async {
                for fn in self.errorResolutions {
                    fn(err)
                }
                self.errorResolutions = []
            }
        }
    }

    private func resolve(_ resolve: @escaping ResolveCallback ) {
        if let result = result {
            DispatchQueue.main.async {
                resolve(result)
            }
        } else {
            successResolutions.append(resolve)
            do {
                try fn?(fulfill, reject)
            } catch {
                reject(err: error)
            }
        }
    }

    @discardableResult func then<U>(_ next: @escaping ((T) -> Promise<U>) ) -> Promise<U> {
        return Promise<U> { fulfill, reject in
            self.catch { (err) in
                reject(err)
            }.resolve { result in
                next(result).catch { (err) in
                    reject(err)
                }.then { (finalResult) in
                    fulfill(finalResult)
                }
            }
        }
    }

    @discardableResult func then<U>(_ next: @escaping ((T) throws -> U) ) -> Promise<U> {
        return Promise<U> { fulfill, reject in
            self.catch { (err) in
                reject(err)
            }.resolve { result in
                do {
                    let x = try next(result)
                    fulfill(x)
                } catch {
                    reject(error)
                }
            }
        }
    }

    @discardableResult func `catch`(_ resolve: @escaping ErrorCallback ) -> Promise<T> {
        if let error = error {
            DispatchQueue.main.async {
                resolve(error)
            }
        } else {
            errorResolutions.append(resolve)
        }
        return self
    }

}



