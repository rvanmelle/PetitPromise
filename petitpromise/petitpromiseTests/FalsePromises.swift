//
//  FalsePromises.swift
//  petitpromise
//
//  Created by Reid van Melle on 2017-03-11.
//  Copyright © 2017 rvanmelle. All rights reserved.
//

import Foundation
@testable import petitpromise

enum FakeError: Error {
    case tooMuchVanilla
    case tooSpicy
}

let htmlFailure = false
let countStringFailure = false

func getHTML(_ url:String) -> Promise<String> {
    let url = URL(string: url)
    return Promise { fullfill, reject in
        let task = URLSession.shared.dataTask(with: url!) { data, response, error in

            if htmlFailure {
                reject(FakeError.tooSpicy)
            } else {
                guard let data = data, error == nil else {
                    reject(error!)
                    return
                }

                let result : String = NSString(data: data, encoding: String.Encoding.utf8.rawValue)! as String
                fullfill(result)
            }
        }

        task.resume()
    }
}

func countString(_ input:String) -> Promise<Int> {
    return Promise { fulfill, reject in
        DispatchQueue.global(qos: .background).async {
            if countStringFailure {
                reject(FakeError.tooMuchVanilla)
            } else {
                let cnt = input.characters.count
                fulfill(cnt)
            }
        }
    }
}

func computeStringSize(_ input:String) -> Int {
    return input.characters.count
}

