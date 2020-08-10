
//  The MIT License (MIT)
//
//  Copyright (c) 2016 Dmitry Kozlov
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in all
//  copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
//  SOFTWARE.

import Foundation

public protocol LosslessDataConvertible {
  var data: Data { get }
}
extension Data: LosslessDataConvertible {
  public var data: Data { self }
}
extension String: LosslessDataConvertible {
  public var data: Data {
    return data(using: .utf8)!
  }
}

public func json(_ object: Any?) -> Data! {
  guard let object = object else { return nil }
  return try? JSONSerialization.data(withJSONObject: object, options: .prettyPrinted)
}

extension String {
  //  public var uuidData: Data {
  //    var data = Data()
  //    let password = hashValue
  //    for i in 1...16 {
  //      let v = UInt64.seed(password, i)
  //      let b = UInt8(v & 0xFF)
  //      data.append(b)
  //    }
  //    return data
  //  }
  //  public var uuid: String {
  //    return uuidData.uuidString
  //  }
//  public var hex: Data {
//    return Data(hex: self)
//  }
}

extension Data {
  public var json: Any! {
    do {
      return try JSONSerialization.jsonObject(with: self, options: [.mutableContainers, .mutableLeaves])
    } catch {
      return nil
    }
  }
  /// - Parameter length: Desired data length
  /// - Returns: Random data
  public static func random(_ length: Int) -> Data {
    var data = Data(repeating: 0, count: length)
    var success = false
    #if !os(Linux)
    let result = data.withUnsafeMutableBytes { (pointer: UnsafeMutableRawBufferPointer) in
      SecRandomCopyBytes(kSecRandomDefault, length, pointer.baseAddress!)
    }
    success = result == errSecSuccess
    #endif
    guard !success else { return data }
    data.withUnsafeMutableBytes { bytes in
      for i in 0..<length {
        #if canImport(Darwin)
        bytes[i] = UInt8(arc4random() & 0xff)
        #else
        bytes[i] = UInt8(rand() & 0xff)
        #endif
      }
    }
    return data
  }
}

public extension Data {
  init<T>(_ value: T) where T: FixedWidth {
    var value = value
    var data: Data!
    withUnsafePointer(to: &value) { value in
      data = Data(buffer: UnsafeBufferPointer(start: value, count: 1))
    }
    self = data
  }
  mutating func append<T>(_ value: T) where T: RawRepresentable, T.RawValue: FixedWidth {
    append(value.rawValue)
  }
  mutating func append<T>(_ value: T) where T: FixedWidth {
    var value = value
    withUnsafePointer(to: &value) { append(UnsafeBufferPointer(start: $0, count: 1)) }
  }
  func normalized(to blockSize: Int) -> Data {
    var data = self
    data.normalize(to: blockSize)
    return data
  }
  mutating func normalize(to blockSize: Int) {
    let a = blockSize - count % blockSize
    guard a > 0 else { return }
    append(Data(count: a))
  }
  mutating func replace<T>(at index: Int, with value: T) where T: DataRepresentable {
    var value = value
    let end = index + MemoryLayout<T>.size
    withUnsafePointer(to: &value) { value in
      replaceSubrange(index..<end , with: UnsafeBufferPointer(start: value, count: 1))
    }
  }
  func convert<T,S>() throws -> T where T: RawRepresentable, S: DataRepresentable, T.RawValue == S {
    if let value = T(rawValue: convert()) {
      return value
    } else {
      throw corrupted
    }
  }
  func convert<T: DataRepresentable>() -> T {
    withUnsafeBytes {
      $0.bindMemory(to: T.self).baseAddress!.pointee
    }
  }
  func convert<T>() -> Array<T> where T: DataRepresentable {
    return withUnsafeBytes {
      Array<T>($0.bindMemory(to: T.self))
    }
  }
  func convert<T>() -> Set<T> where T: DataRepresentable {
    return withUnsafeBytes {
      Set($0.bindMemory(to: T.self))
    }
  }
  func convert<T>() -> ArraySlice<T> where T: DataRepresentable {
    return withUnsafeBytes {
      ArraySlice($0.bindMemory(to: T.self))
    }
  }
}

public extension Data {
  var mutableVoidPointer: UnsafeMutablePointer<Int8> {
    mutating get {
      mutableBaseAddress.bindMemory(to: Int8.self, capacity: 1)
    }
  }
  var voidPointer: UnsafePointer<Int8> {
    baseAddress.bindMemory(to: Int8.self, capacity: 1)
  }
  var mutableBaseAddress: UnsafeMutableRawPointer {
    mutating get {
      self.withUnsafeMutableBytes { $0.baseAddress! }
    }
  }
  var baseAddress: UnsafeRawPointer {
    withUnsafeBytes { $0.baseAddress! }
  }
  var baseAddress8: UnsafePointer<UInt8> {
    withUnsafeBytes { $0.baseAddress!.bindMemory(to: UInt8.self, capacity: 1) }
  }
  var mutableBaseAddress8: UnsafeMutablePointer<UInt8> {
    mutating get {
      withUnsafeMutableBytes { $0.baseAddress!.bindMemory(to: UInt8.self, capacity: 1) }
    }
  }
}
