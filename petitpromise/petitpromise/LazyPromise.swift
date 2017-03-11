//
//  LazyPromise.swift
//  petitpromise
//
//  Created by Reid van Melle on 2017-03-11.
//  Copyright © 2017 rvanmelle. All rights reserved.
//

import Foundation

class LazyPromise<T>: Promise<T> {
    override init(_ fn: @escaping PromiseCallback) {
        super.init { fullfill, reject in }
        self.fn = fn
    }
}
