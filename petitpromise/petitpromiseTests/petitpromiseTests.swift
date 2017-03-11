//
//  petitpromiseTests.swift
//  petitpromiseTests
//
//  Created by Reid van Melle on 2017-03-10.
//  Copyright © 2017 rvanmelle. All rights reserved.
//

import XCTest
@testable import petitpromise

enum TestError: Error {
    case error1
    case error2
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

    func testSimpleAsync() {
        let expect = expectation(description: "promise")

        Promise { (fulfill, reject) in
            DispatchQueue.global(qos: .default).async {
                fulfill()
            }
        }.then { () -> Void in
            expect.fulfill()
        }

        waitForExpectations(timeout: 5) { (err) in }
    }


    func testSimpleSync() {
        let expect = expectation(description: "promise")

        Promise { (fulfill, reject) in
            fulfill()
        }.then { () -> Void in
            expect.fulfill()
        }

        waitForExpectations(timeout: 5) { (err) in }
    }

    func testAsyncThen() {
        let expect = expectation(description: "promise")
        var result = 0

        Promise { (fulfill, reject) in
            DispatchQueue.global(qos: .default).async {
                fulfill()
            }
        }.then { () -> Promise<Int> in
            return Promise { (fulfill, reject) in
                DispatchQueue.global(qos: .default).async {
                    fulfill(5)
                }
            }
        }.then { (theInteger) -> Void in
            result = theInteger
            expect.fulfill()
        }

        waitForExpectations(timeout: 5) { (err) in
            XCTAssert(result == 5)
        }

    }

    func testSyncThen() {
        let expect = expectation(description: "promise")
        var result = 0

        Promise { (fulfill, reject) in
            DispatchQueue.global(qos: .default).async {
                fulfill()
            }
        }.then { () -> Int in
            return 5
        }.then { (theInteger) in
            result = theInteger
            expect.fulfill()
        }

        waitForExpectations(timeout: 5) { (err) in
            XCTAssert(result == 5)
        }
    }

    func testSimpleError() {
        let expect = expectation(description: "promise")
        Promise<Void> { (fulfill, reject) in
            DispatchQueue.global(qos: .default).async {
                reject(TestError.error1)
            }
        }.whoops { (err) in
            XCTAssert(err as! TestError == TestError.error1)
            expect.fulfill()
        }

        waitForExpectations(timeout: 5) { (err) in }
    }

    func testExceptions() {
        let expect = expectation(description: "promise")
        Promise<Void> { (fulfill, reject) in
            throw TestError.error2
        }.whoops { (err) in
            XCTAssert(err as! TestError == TestError.error2)
            expect.fulfill()
        }

        waitForExpectations(timeout: 5) { (err) in }
    }

    func testThenException() {
        let expect = expectation(description: "promise")

        Promise { (fulfill, reject) in
            DispatchQueue.global(qos: .default).async {
                fulfill()
            }
        }.then { () -> Int in
            throw TestError.error1
        }.whoops { (err) in
            XCTAssert(err as! TestError == TestError.error1)
            expect.fulfill()
        }

        waitForExpectations(timeout: 5) { (err) in }
    }

    func testThenPromiseException() {
        let expect = expectation(description: "promise")

        Promise { (fulfill, reject) in
            DispatchQueue.global(qos: .default).async {
                fulfill()
            }
        }.then { () -> Promise<Void> in
            return Promise<Void> { (fulfill, reject) in
                throw TestError.error2
            }
        }.whoops { (err) in
            XCTAssert(err as! TestError == TestError.error2)
            expect.fulfill()
        }

        waitForExpectations(timeout: 5) { (err) in }
    }


    func testLongChain() {
        let expect = expectation(description: "promise")

        func addOne(_ cur:Int) -> Int {
            return cur + 1
        }

        var result = 0
        Promise { (fulfill, reject) in
            DispatchQueue.global(qos: .default).async {
                fulfill(1)
            }
        }.then(addOne).then(addOne).then(addOne).then(addOne).then(addOne).then(addOne).then(addOne)
        .then { (val) -> Void in
            result = val
            expect.fulfill()
        }

        waitForExpectations(timeout: 5) { (err) in
            XCTAssert(result == 8)
        }
    }

    func testMultipleThens() {
        /**
         This is more of a white box test. We know how the execution works. The graph is
         executed breadth first, so all of the side-effects should be executed before
         the expectation is fulfilled.
         
         Recommended usage in this case would be to use Promise.all
        */
        let expect = expectation(description: "promise")

        var result = 0
        let p = Promise { (fulfill, reject) in
            DispatchQueue.global(qos: .default).async {
                fulfill(1)
            }
        }
        p.then { (val) -> Void in result += 1 }
        p.then { (val) -> Void in result += 1 }
        p.then { (val) -> Void in result += 1 }
        p.then { (val) -> Void in result += 1 }
        .then {
            expect.fulfill()
        }
        p.then { (val) -> Void in result += 1 }

        waitForExpectations(timeout: 5) { (err) in
            XCTAssert(result == 5)
        }
    }

    func testMultipleErrors() {
        /**
         When an error occurs in the chain, it bubbles up. The first error should rule them all.
        */
        let expect = expectation(description: "promise")

        Promise { (fulfill, reject) in
            DispatchQueue.global(qos: .default).async {
                fulfill()
            }
        }.then { () -> Void in
            throw TestError.error1
        }.then { () -> Void in
            throw TestError.error2
        }.whoops { (err) in
            XCTAssert(err as! TestError == TestError.error1)
            expect.fulfill()
        }

        waitForExpectations(timeout: 5) { (err) in }
    }

}
