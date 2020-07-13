import XCTest

import xcodeTests

var tests = [XCTestCaseEntry]()
tests += xcodeTests.allTests()
XCTMain(tests)
