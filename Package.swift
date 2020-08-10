// swift-tools-version:5.2
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

// Support class
// All relations located at the bottom
class Targets {
  var array = [PackageDescription.Target]()
  private var _executables = [String]()
  private var _libraries = [String]()
  private var _dependencies = [String]()
  var products: [PackageDescription.Product] {
    _libraries.map { PackageDescription.Product.library(name: $0, targets: [$0]) }
      + _executables.map { PackageDescription.Product.executable(name: $0, targets: [$0])}
  }
  var dependencies: [Package.Dependency] {
    return _dependencies.map {
      let array = $0.split(separator: " ")
      return Package.Dependency.package(url: "https://github.com/\(array[0]).git", .upToNextMajor(from: .init(stringLiteral: "\(array[1])")))
    }
  }
  func git(_ name: String) -> Self {
    let framework = String(name.split(separator: " ").first!.split(separator: "/").last!)
    _libraries.append(framework)
    _dependencies.append(name)
    return self
  }
  func app(_ name: String) -> Self {
    let array = name.split(separator: " ")
    _executables.append(String(array[0]))
    return set(name)
  }
  func set(_ name: String) -> Self {
    guard !name.isEmpty else { return self }
    let array = name.split(separator: " ")
    let name = String(array[0])
    _libraries.append(name)
    let dependencies = array.dropFirst().map {
      Target.Dependency(stringLiteral: String($0))
    }
    self.array.append(.target(name: name, dependencies: dependencies))
    return self
  }
  func some() -> Self {
    array.last!.dependencies.append("SomeFunctions")
    array.last!.dependencies.append("SomeData")
    return self
  }
  func test() -> Self {
    let name = array.last!.name
    array.append(.testTarget(name: name + "Tests", dependencies: [Target.Dependency(stringLiteral: name)]))
    return self
  }
}

let targets = Targets()
  .set("Some")
  .set("SomeUI Some")

let package = Package(
  name: "SomeFunctionsApp",
  platforms: [.iOS(.v11), .macOS(.v10_15)],
  products: targets.products,
  dependencies: [],
  targets: targets.array
)
