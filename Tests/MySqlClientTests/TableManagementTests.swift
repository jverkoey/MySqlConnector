// Copyright 2019-present the MySqlClient authors. All Rights Reserved.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

import BinaryCodable
@testable import MySqlClient
import XCTest

final class TableManagementTests: MySqlClientHarnessTestCase {
  override func setUp() {
    super.setUp()

    try! client.query("create database \(type(of: self))")
  }

  override func tearDown() {
    try! client.query("drop database \(type(of: self))")

    super.tearDown()
  }

  func testFailsToCreateTableWithoutSelectingDatabase() throws {
    // When
    let creationResponse = try client.query("create table \(type(of: self))")

    // Then
    switch creationResponse {
    case .ERR(let errorCode, let errorMessage):
      XCTAssertEqual(errorCode, .noDbError)
      XCTAssertEqual(errorMessage, "No database selected")
    default:
      XCTFail("Unexpected response \(creationResponse)")
    }
  }

  func testFailsToCreateTableWithoutColumns() throws {
    // When
    let useResponse = try client.query("use \(type(of: self))")
    let creationResponse = try client.query("create table \(type(of: self))")

    // Then
    switch useResponse {
    case .OK(let numberOfAffectedRows, let lastInsertId, let info):
      XCTAssertEqual(numberOfAffectedRows, 0)
      XCTAssertEqual(lastInsertId, 0)
      XCTAssertEqual(info, "")
    default:
      XCTFail("Unexpected response \(creationResponse)")
    }
    switch creationResponse {
    case .ERR(let errorCode, let errorMessage):
      XCTAssertEqual(errorCode, .tableMustHaveColumns)
      XCTAssertEqual(errorMessage, "A table must have at least 1 column")
    default:
      XCTFail("Unexpected response \(creationResponse)")
    }
  }

  func testCreatesAndDropsTable() throws {
    // When
    let useResponse = try client.query("use \(type(of: self))")
    // Example query from https://dev.mysql.com/doc/refman/5.7/en/creating-tables.html
    let creationResponse = try client.query("create table \(type(of: self)) (name VARCHAR(20), owner VARCHAR(20), species VARCHAR(20), sex CHAR(1), birth DATE, death DATE)")
    let dropResponse = try client.query("drop table \(type(of: self))")

    // Then
    switch useResponse {
    case .OK(let numberOfAffectedRows, let lastInsertId, let info):
      XCTAssertEqual(numberOfAffectedRows, 0)
      XCTAssertEqual(lastInsertId, 0)
      XCTAssertEqual(info, "")
    default:
      XCTFail("Unexpected response \(creationResponse)")
    }
    switch creationResponse {
    case .OK(let numberOfAffectedRows, let lastInsertId, let info):
      XCTAssertEqual(numberOfAffectedRows, 0)
      XCTAssertEqual(lastInsertId, 0)
      XCTAssertNil(info)
    default:
      XCTFail("Unexpected response \(creationResponse)")
    }
    switch dropResponse {
    case .OK(let numberOfAffectedRows, let lastInsertId, let info):
      XCTAssertEqual(numberOfAffectedRows, 0)
      XCTAssertEqual(lastInsertId, 0)
      XCTAssertNil(info)
    default:
      XCTFail("Unexpected response \(creationResponse)")
    }
  }
}
