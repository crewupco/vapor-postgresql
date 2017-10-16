// swift-tools-version:4.0

import PackageDescription

let package = Package(
  name: "VaporPostgreSQL",
  products: [
    .library(name: "VaporPostgreSQL", targets: ["VaporPostgreSQL"])
  ],
  dependencies: [
    .package(url: "https://github.com/vapor/cpostgresql.git", .upToNextMajor(from: "2.0.0"))
  ],
  targets: [
    .target(name: "VaporPostgreSQL", dependencies: ["CPostgreSQL"]),
    .testTarget(name: "VaporPostgreSQLTests", dependencies: ["VaporPostgreSQL"])
  ]
)
