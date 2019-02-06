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
    ),
  ],
  targets: [
    .target(
      name: "MySqlConnector",
      dependencies: [
        "FixedWidthInteger+bytes",
        "LengthEncodedInteger",
        "LengthEncodedString"
      ]
    ),
    .testTarget(
      name: "MySqlConnectorTests",
      dependencies: ["MySqlConnector"]
    ),

    .target(
      name: "FixedWidthInteger+bytes",
      dependencies: []
    ),
    .testTarget(
      name: "FixedWidthInteger+bytesTests",
      dependencies: ["FixedWidthInteger+bytes"]
    ),

    .target(
      name: "LengthEncodedInteger",
      dependencies: [
        "FixedWidthInteger+bytes"
      ]
    ),
    .testTarget(
      name: "LengthEncodedIntegerTests",
      dependencies: [
        "LengthEncodedInteger",
        "FixedWidthInteger+bytes"
      ]
    ),

    .target(
      name: "LengthEncodedString",
      dependencies: [
        "LengthEncodedInteger"
      ]
    ),
    .testTarget(
      name: "LengthEncodedStringTests",
      dependencies: [
        "LengthEncodedString",
        "FixedWidthInteger+bytes"
      ]
    ),
  ]
)
