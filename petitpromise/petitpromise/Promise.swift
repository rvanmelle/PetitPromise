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
    typealias PromiseCallback = ( ( @escaping ResolveCallback, @escaping ErrorCallback ) -> Void )

    internal var fn: PromiseCallback?
    private var result: T?
    private var error: Error?

    init(_ fn: @escaping PromiseCallback) {
        fn(fulfill, reject)
    }

    private var successResolutions: [ResolveCallback] = []
    private var errorResolutions: [ErrorCallback] = []

    // called by an async function when it obtains a result
    // result is passed onto all waiting functions
    private func fulfill(result:T) {
        self.result = result
        for fn in successResolutions {
            fn(result)
        }
        successResolutions = []
    }

    private func reject(err:Error) {
        self.error = err
        for fn in errorResolutions {
            fn(err)
        }
        errorResolutions = []
    }

    private func resolve(_ resolve: @escaping ResolveCallback ) {
        if let result = result {
            resolve(result)
        } else {
            successResolutions.append(resolve)
            fn?(fulfill, reject)
        }
    }

    @discardableResult func then<U>(_ next: @escaping ((T) -> Promise<U>) ) -> Promise<U> {
        return Promise<U> { fulfill, reject in
            self.whoops { (err) in
                reject(err)
                }.resolve { result in
                    next(result).whoops { (err) in
                        reject(err)
                        }.resolve { (finalResult) in
                            fulfill(finalResult)
                    }
            }
        }
    }

    @discardableResult func then<U>(_ next: @escaping ((T) -> U) ) -> Promise<U> {
        return Promise<U> { fulfill, reject in
            self.whoops { (err) in
                reject(err)
                }.resolve { result in
                    let x = next(result)
                    fulfill(x)
            }
        }
    }

    @discardableResult func whoops(_ resolve: @escaping ErrorCallback ) -> Promise<T> {
        if let error = error {
            resolve(error)
        } else {
            errorResolutions.append(resolve)
        }
        return self
    }

}


/*
 infix operator => { associativity left precedence 160 }
 func =><A,B>(_ input:Promise<A>, _ output:Promise<B>) -> Promise<B> {
 return Promise { fulfill, reject in
 input.then({ (val) in

 })
 }
 }*/



