import XCTest
import class Foundation.Bundle
@testable import Some

final class SomeTests: XCTestCase {
  func testPerformanceUInt256() {
    var value = UInt256(0, 0, 0, 0)
    let increment: UInt256 = 1
    measure {
      for _ in 0..<100_000 {
        value &+= increment
      }
    }
    print(value)
  }
  func testSIMD4() {
    var value = SIMD4<UInt64>([1, 0, 0, 0])
    let increment: SIMD4<UInt64> = [UInt64.max, 0, 0, 0]
    value &+= increment
    print(value)
  }
  func testPerformanceSIMD4() {
    var value = SIMD4<UInt64>([0, 0, 0, 0])
    let increment: SIMD4<UInt64> = [1, 0, 0, 0]
    measure {
      for _ in 0..<100_000 {
        value &+= increment
      }
    }
    print(value)
  }
  func testPerformanceSIMD2() {
    var value = SIMD2<UInt64>([1, 1])
    let increment: SIMD2<UInt64> = [2, 1]
    measure {
      for _ in 0..<100_000 {
        value &+= increment
      }
    }
    print(value)
  }
  
  func testExample() throws {
    // This is an example of a functional test case.
    // Use XCTAssert and related functions to verify your tests produce the correct
    // results.
    
    // Some of the APIs that we use below are available in macOS 10.13 and above.
    guard #available(macOS 10.13, *) else {
      return
    }
    
    let fooBinary = productsDirectory.appendingPathComponent("Some")
    
    let process = Process()
    process.executableURL = fooBinary
    
    let pipe = Pipe()
    process.standardOutput = pipe
    
    try process.run()
    process.waitUntilExit()
    
    let data = pipe.fileHandleForReading.readDataToEndOfFile()
    let output = String(data: data, encoding: .utf8)
    
    XCTAssertEqual(output, "Hello, world!\n")
  }
  
  /// Returns path to the built products directory.
  var productsDirectory: URL {
    #if os(macOS)
    for bundle in Bundle.allBundles where bundle.bundlePath.hasSuffix(".xctest") {
      return bundle.bundleURL.deletingLastPathComponent()
    }
    fatalError("couldn't find the products directory")
    #else
    return Bundle.main.bundleURL
    #endif
  }
  
  static var allTests = [
    ("testExample", testExample),
  ]
}
