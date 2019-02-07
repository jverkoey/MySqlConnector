import XCTest

import LengthEncodedStringTests
import LengthEncodedIntegerTests
import MySqlConnectorTests
import FixedWidthInteger_bytesTests
import IteratorProtocol_nextTests
import CustomStringConvertible_descriptionTests
import Data_xoredTests

var tests = [XCTestCaseEntry]()
tests += LengthEncodedStringTests.__allTests()
tests += LengthEncodedIntegerTests.__allTests()
tests += MySqlConnectorTests.__allTests()
tests += FixedWidthInteger_bytesTests.__allTests()
tests += IteratorProtocol_nextTests.__allTests()
tests += CustomStringConvertible_descriptionTests.__allTests()
tests += Data_xoredTests.__allTests()

XCTMain(tests)
