// swift-tools-version:4.2
// Copyright 2019-present the MySqlConnector authors. All Rights Reserved.
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

import PackageDescription

let package = Package(
  name: "MySqlConnector",
  products: [
    .library(
      name: "MySqlConnector",
      targets: ["MySqlConnector"]
    )
  ],
  dependencies: [
    .package(url: "https://github.com/IBM-Swift/BlueSocket.git", .upToNextMajor(from: "1.0.0")),
    .package(url: "https://github.com/IBM-Swift/BlueCryptor.git", .upToNextMajor(from: "1.0.0")),
    .package(url: "https://github.com/jverkoey/BinaryCodable.git", .upToNextMajor(from: "0.1.0"))
  ],
  targets: [
    .target(
      name: "MySqlConnector",
      dependencies: [
        "Cryptor",
        "BinaryCodable",
        "MySqlQuery",
        "Socket",
      ]
    ),
    .testTarget(
      name: "MySqlConnectorTests",
      dependencies: ["MySqlConnector"]
    ),

    .target(
      name: "MySqlQuery",
      dependencies: []
    ),
    .testTarget(
      name: "MySqlQueryTests",
      dependencies: ["MySqlQuery"]
    )
  ]
)
