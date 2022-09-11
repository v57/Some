// swift-tools-version:5.6
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
  name: "Some",
  platforms: [
    .iOS(.v13),
    .macOS(.v10_15),
  ],
  products: [
    .library(name: "SomeUI", targets: ["SomeUI"]),
    .library(name: "Some", targets: ["Some"])
  ],
  targets: [
    .target(name: "SomeC", dependencies: []),
    .target(name: "Some", dependencies: ["SomeC"]),
    .target(name: "SomeUI", dependencies: ["Some"]),
  ]
)
