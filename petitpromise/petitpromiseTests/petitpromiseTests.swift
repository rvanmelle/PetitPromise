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
        let _ : Promise<Void> = Promise { (fulfill, reject) in
            DispatchQueue.global(qos: .default).async {
                reject(TestError.error1)
            }
        }.whoops { (err) in
            expect.fulfill()
        }

        waitForExpectations(timeout: 5) { (err) in }
    }

    func testExceptions() {

    }

    func testLongChain() {

    }

    func testMultipleThens() {

    }

    func testMultipleErrors() {

    }

}
