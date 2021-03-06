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
import Cryptor
import Foundation

/**
 Documentation: https://dev.mysql.com/doc/internals/en/connection-phase-packets.html
 */
struct HandshakeResponse: BinaryEncodable, CustomStringConvertible {
  let username: String
  let password: String
  let database: String?
  let capabilityFlags: CapabilityFlags
  let authPluginData: Data
  let authPluginName: String?

  func encode(to encoder: BinaryEncoder) throws {
    var container = encoder.container()

    try container.encode(capabilityFlags)

    let maxPacketLength: UInt32 = 0
    try container.encode(maxPacketLength)

    try container.encode(CharacterSet.utf8Mb4GeneralCi)

    let reserved = [UInt8](repeating: 0, count: 23)
    try container.encode(sequence: reserved)

    try container.encode(username, encoding: .utf8, terminator: 0)

    if capabilityFlags.contains(.secureConnection) {
      if password.isEmpty {
        // The server implementation treats empty passwords as a special case:
        // https://github.com/mysql/mysql-server/blob/8e797a5d6eb3a87f16498edcb7261a75897babae/sql/auth/sql_authentication.cc#L3753-L3756
        // In essence: empty passwords aren't sent back in the response.
        try container.encode(UInt8(0))
      } else {
        // Secure authentication is one byte of length and then the auth data.
        // Docs: https://dev.mysql.com/doc/internals/en/secure-password-authentication.html#packet-Authentication::Native41
        let authDataPart1: Data = CryptoUtils.data(fromHex: password.sha1)
        let authDataPart2: Data = (authPluginData + authDataPart1.sha1).sha1
        let authData = authDataPart1.xored(with: authDataPart2)
        try container.encode(UInt8(authData.count))
        try container.encode(sequence: authData)
      }
    }

    if capabilityFlags.contains(.connectWithDb) {
      try container.encode(database ?? "", encoding: .utf8, terminator: 0)
    }

    if capabilityFlags.contains(.pluginAuth) {
      try container.encode(authPluginName ?? "", encoding: .utf8, terminator: 0)
    }
  }
}
