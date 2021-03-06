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
import Foundation

/**
 A query can be sent a MySql server as a text-based query that is executed immediately.

 Docs: https://dev.mysql.com/doc/internals/en/com-query.html
 */
struct Query: BinaryEncodable {
  let query: String
  init(_ query: String) {
    self.query = query
  }

  func encode(to encoder: BinaryEncoder) throws {
    var container = encoder.container()
    try container.encode(UInt8(0x03))
    try container.encode(query, encoding: .utf8, terminator: 0)
  }
}

final class QueryResultDecoder<T: Decodable>: IteratorProtocol {
  let connection: Connection
  let columnDefinitions: [ColumnDefinition]

  deinit {
    if !connection.isIdle {
      // We kill the connection when this instance is released before the results have been fully exhausted, because
      // otherwise this connection would never transition to an idle state.
      // TODO: Explore sending COM_RESET_CONNECTION instead.
      // https://dev.mysql.com/doc/internals/en/com-reset-connection.html
      connection.terminate()
    }
  }

  init(columnCount: UInt64, connection: Connection) throws {
    self.connection = connection

    columnDefinitions = try (0..<columnCount).map { _ in
      return try connection.read(payloadType: ColumnDefinition.self)
    }
  }

  func next() -> T? {
    do {
      let resultsetRow = try connection.read(payloadType: Resultset.self)
      switch resultsetRow {
      case .eof:
        return nil
      case .row(let values):
        let decoder = RowDecoder(columnDefinitions: columnDefinitions, values: values)
        return try T(from: decoder)
      }
    } catch let error {
      assertionFailure(String(describing: error))
      return nil
    }
  }
}

private final class RowDecoder: Decoder {
  let columnDefinitions: [ColumnDefinition]
  let storage: [String: String?]
  init(columnDefinitions: [ColumnDefinition], values: [String?]) {
    self.columnDefinitions = columnDefinitions
    self.storage = Dictionary(uniqueKeysWithValues: zip(columnDefinitions.map { $0.name }, values))
  }

  var codingPath: [CodingKey] = []
  var userInfo: [CodingUserInfoKey: Any] = [:]

  func container<Key>(keyedBy type: Key.Type) throws -> KeyedDecodingContainer<Key> where Key: CodingKey {
    let container = RowKeyedDecodingContainer<Key>(decoder: self)
    return KeyedDecodingContainer(container)
  }

  func singleValueContainer() throws -> SingleValueDecodingContainer {
    precondition(storage.count == 1, "Only single-value responses are supported when converting to an array")
    return RowSingleValueDecodingContainer(decoder: self)
  }

  func unkeyedContainer() throws -> UnkeyedDecodingContainer { preconditionFailure("Unimplemented") }
}

private final class RowKeyedDecodingContainer<K: CodingKey>: KeyedDecodingContainerProtocol {
  typealias Key = K

  let codingPath: [CodingKey]
  var allKeys: [K] {
    return decoder.columnDefinitions.compactMap { Key(stringValue: $0.name) }
  }

  let decoder: RowDecoder
  init(decoder: RowDecoder) {
    self.decoder = decoder
    self.codingPath = decoder.codingPath
  }

  func contains(_ key: K) -> Bool {
    return decoder.storage[key.stringValue] != nil
  }

  func decode(_ type: String.Type, forKey key: K) throws -> String { return try decodeLossless(type, forKey: key) }
  func decode(_ type: Double.Type, forKey key: K) throws -> Double { return try decodeLossless(type, forKey: key) }
  func decode(_ type: Float.Type, forKey key: K) throws -> Float { return try decodeLossless(type, forKey: key) }
  func decode(_ type: Int.Type, forKey key: K) throws -> Int { return try decodeLossless(type, forKey: key) }
  func decode(_ type: Int8.Type, forKey key: K) throws -> Int8 { return try decodeLossless(type, forKey: key) }
  func decode(_ type: Int16.Type, forKey key: K) throws -> Int16 { return try decodeLossless(type, forKey: key) }
  func decode(_ type: Int32.Type, forKey key: K) throws -> Int32 { return try decodeLossless(type, forKey: key) }
  func decode(_ type: Int64.Type, forKey key: K) throws -> Int64 { return try decodeLossless(type, forKey: key) }
  func decode(_ type: UInt.Type, forKey key: K) throws -> UInt { return try decodeLossless(type, forKey: key) }
  func decode(_ type: UInt8.Type, forKey key: K) throws -> UInt8 { return try decodeLossless(type, forKey: key) }
  func decode(_ type: UInt16.Type, forKey key: K) throws -> UInt16 { return try decodeLossless(type, forKey: key) }
  func decode(_ type: UInt32.Type, forKey key: K) throws -> UInt32 { return try decodeLossless(type, forKey: key) }
  func decode(_ type: UInt64.Type, forKey key: K) throws -> UInt64 { return try decodeLossless(type, forKey: key) }

  func decodeNil(forKey key: K) throws -> Bool {
    guard let value = decoder.storage[key.stringValue] else {
      return true
    }
    return value == nil
  }

  // TODO: Share this implementation across the decoder implementations.
  func decode(_ type: Bool.Type, forKey key: K) throws -> Bool {
    guard let valueOrNil = decoder.storage[key.stringValue],
      let value = valueOrNil else {
        throw DecodingError.valueNotFound(type,
                                          DecodingError.Context(codingPath: decoder.codingPath,
                                                                debugDescription: "\(key) was not found."))
    }
    let trueValues = Set(["YES"])
    let falseValues = Set(["NO"])
    if trueValues.contains(value) {
      return true
    }
    if falseValues.contains(value) {
      return false
    }
    throw DecodingError.typeMismatch(type,
                                     DecodingError.Context(codingPath: decoder.codingPath,
                                                           debugDescription: "\(key.stringValue) was not convertible to \(type)."))
  }

  // TODO: Share this implementation across the decoder implementations.
  func decode<T>(_ type: T.Type, forKey key: K) throws -> T where T: Decodable {
    // Special-case handling of Optional<String> decoding for [String: String?] support.
    if type is Optional<String>.Type {
      guard let valueOrNil = decoder.storage[key.stringValue] else {
        throw DecodingError.valueNotFound(type, DecodingError.Context(codingPath: decoder.codingPath, debugDescription: "\(key) was not found."))
      }
      return valueOrNil as! T
    }

    self.decoder.codingPath.append(key)
    defer { self.decoder.codingPath.removeLast() }
    return try T(from: decoder)
  }

  func nestedContainer<NestedKey>(keyedBy type: NestedKey.Type, forKey key: K) throws -> KeyedDecodingContainer<NestedKey> where NestedKey: CodingKey {
    throw DecodingError.typeMismatch(type, DecodingError.Context(codingPath: decoder.codingPath, debugDescription: "\(key) was not convertible to \(type)."))
  }

  // TODO: Share this implementation across the decoder implementations.
  private func decodeLossless<T: LosslessStringConvertible>(_ type: T.Type, forKey key: K) throws -> T {
    guard let valueOrNil = decoder.storage[key.stringValue],
      let value = valueOrNil else {
        throw DecodingError.valueNotFound(type,
                                          DecodingError.Context(codingPath: decoder.codingPath,
                                                                debugDescription: "\(key) was not found."))
    }
    guard let typedValue = type.init(value) else {
      throw DecodingError.typeMismatch(type,
                                       DecodingError.Context(codingPath: decoder.codingPath,
                                                             debugDescription: "\(key.stringValue) was not convertible to \(type)."))
    }
    return typedValue
  }

  func nestedUnkeyedContainer(forKey key: K) throws -> UnkeyedDecodingContainer { preconditionFailure("Unimplemented") }
  func superDecoder() throws -> Decoder { preconditionFailure("Unimplemented") }
  func superDecoder(forKey key: K) throws -> Decoder { preconditionFailure("Unimplemented") }
}

private final class RowSingleValueDecodingContainer: SingleValueDecodingContainer {
  let codingPath: [CodingKey]

  let decoder: RowDecoder
  init(decoder: RowDecoder) {
    self.decoder = decoder
    self.codingPath = decoder.codingPath
  }

  func decode(_ type: Bool.Type) throws -> Bool { return try decodeLossless(type) }
  func decode(_ type: String.Type) throws -> String { return try decodeLossless(type) }
  func decode(_ type: Double.Type) throws -> Double { return try decodeLossless(type) }
  func decode(_ type: Float.Type) throws -> Float { return try decodeLossless(type) }
  func decode(_ type: Int.Type) throws -> Int { return try decodeLossless(type) }
  func decode(_ type: Int8.Type) throws -> Int8 { return try decodeLossless(type) }
  func decode(_ type: Int16.Type) throws -> Int16 { return try decodeLossless(type) }
  func decode(_ type: Int32.Type) throws -> Int32 { return try decodeLossless(type) }
  func decode(_ type: Int64.Type) throws -> Int64 { return try decodeLossless(type) }
  func decode(_ type: UInt.Type) throws -> UInt { return try decodeLossless(type) }
  func decode(_ type: UInt8.Type) throws -> UInt8 { return try decodeLossless(type) }
  func decode(_ type: UInt16.Type) throws -> UInt16 { return try decodeLossless(type) }
  func decode(_ type: UInt32.Type) throws -> UInt32 { return try decodeLossless(type) }
  func decode(_ type: UInt64.Type) throws -> UInt64 { return try decodeLossless(type) }

  func decodeNil() -> Bool {
    guard let element = decoder.storage.first else {
      return true
    }
    return element.value == nil
  }

  func decode<T>(_ type: T.Type) throws -> T where T: Decodable {
    // Special-case handling of Optional<String> decoding for [String: String?] support.
    if type is Optional<String>.Type {
      guard let element = decoder.storage.first else {
        throw DecodingError.valueNotFound(type, DecodingError.Context(codingPath: decoder.codingPath, debugDescription: "value was not found."))
      }
      return element.value as! T
    }

    return try T(from: decoder)
  }

  // TODO: Share this implementation across the decoder implementations.
  private func decodeLossless<T: LosslessStringConvertible>(_ type: T.Type) throws -> T {
    guard let element = decoder.storage.first,
      let value = element.value else {
        throw DecodingError.valueNotFound(type, DecodingError.Context(codingPath: decoder.codingPath, debugDescription: "Value was not found."))
    }
    guard let typedValue = type.init(value) else {
      throw DecodingError.typeMismatch(type, DecodingError.Context(codingPath: decoder.codingPath, debugDescription: "\(value) was not convertible to \(type)."))
    }
    return typedValue
  }
}
