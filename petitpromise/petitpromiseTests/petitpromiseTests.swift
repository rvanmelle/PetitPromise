//
//  petitpromiseTests.swift
//  petitpromiseTests
//
//  Created by Reid van Melle on 2017-03-10.
//  Copyright © 2017 rvanmelle. All rights reserved.
//

import XCTest
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


class petitpromiseTests: XCTestCase {
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testInternetFetch() {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct results.
        let expect = expectation(description: "promise")
        var size = 0

        let x = getHTML("http://www.stackoverflow.com")
            .then(countString)
            .then({ (sz) -> Void in
                size = sz
                print("stackoverflow: \(sz)")
            }).then {
                print("B")
            }.whoops { (err) in
                print("err: \(err)")
            }.then {
                print("C")
            }

        x.then {
            expect.fulfill()
            print("again?")
        }.whoops { (err) in
            print("another error? \(err)")
        }

        waitForExpectations(timeout: 5) { (err) in
            XCTAssert(size > 0)
        }

        
    }
    
    func testPerformanceExample() {
        // This is an example of a performance test case.
        self.measure {
            // Put the code you want to measure the time of here.
        }
    }
    
}
