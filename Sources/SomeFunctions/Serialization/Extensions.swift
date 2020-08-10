
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

public enum DataError: Error {
  case corrupted
}
public var corrupted: Error = DataError.corrupted

public func unraw<T>(_ raw: ArraySlice<UInt8>) -> T {
  return raw.withUnsafeBufferPointer {
    $0.baseAddress!.withMemoryRebound(to: T.self, capacity: 1, { pointer in
      return pointer.pointee
    })
  }
}
public func unraw<T>(_ raw: [UInt8]) -> T {
  return raw.withUnsafeBufferPointer {
    $0.baseAddress!.withMemoryRebound(to: T.self, capacity: 1, { pointer in
      return pointer.pointee
    })
  }
}
public func unraw<T>(_ raw: UnsafeRawPointer) -> T {
  return raw.assumingMemoryBound(to: T.self).pointee
}
public func unraw<T>(_ raw: UnsafePointer<T>) -> T {
  return raw.pointee
}
public func raw(_ pointer: UnsafeRawPointer) -> UnsafeRawPointer {
  return pointer
}


//public protocol DataRepresentable {
//  init(data: DataReader) throws
//  func save(data: DataWriter)
//}
//
//public protocol DataLoadable: class {
//  func load(data: DataReader)
//  func save(data: DataWriter)
//}

public protocol UInt8Enum {
  var rawValue: UInt8 { get }
}

extension Data {
  public init?(path: String) {
    do {
      self = try Data(contentsOf: URL(fileURLWithPath: path))
    } catch {
      return nil
    }
  }
  @inline(__always)
  public func write(to path: String) {
    try? write(to: URL(fileURLWithPath: path))
  }
  public var bytes: [UInt8] {
    return withUnsafeBytes(Array.init)
  }
  @inline(__always)
  public mutating func append(raw: UnsafeRawPointer, length: Int) {
    let pointer = raw.assumingMemoryBound(to: UInt8.self)
    append(pointer, count: length)
  }
  @inline(__always)
  public func copy() -> Data {
    return withUnsafeBytes {
      Data(buffer: $0.bindMemory(to: UInt8.self))
    }
  }
}

extension UInt8 {
  public var hex: String {
    if self < 0x10 {
      return "0" + String(self, radix: 16)
    } else {
      return String(self, radix: 16)
    }
  }
}

extension String {
  public var length: Int {
    return utf8.count
  }
}

extension UInt64 {
  public var bytesString: String {
    if self < UInt64(1).kb {
      return "\(self) bytes"
    } else if self < UInt64(1).mb {
      return "\(self.toKB) KB"
    } else {
      return "\(self.toMB) MB"
    }
  }
  public var kb: UInt64 {
    return self * 1024
  }
  public var mb: UInt64 {
    return self * 1048576
  }
  public var toKB: UInt64 {
    return self / 1024
  }
  public var toMB: UInt64 {
    return self / 1048576
  }
  
  public var hex: String {
    var a = self
    let pointer = raw(&a).assumingMemoryBound(to: UInt8.self)
    var data = Data()
    data.append(pointer, count: 8)
    return data.hex
  }
}

extension FileURL {
  public var reader: DataReader? {
    return DataReader(url: self)
  }
  public func write(data: DataWriter) {
    onCatch("write error") {
      try data.write(to: self)
    }
  }
  public func write(data: Data) {
    onCatch("write error") {
      try data.write(to: self)
    }
  }
}

enum SafeVersionableError: Error, CustomStringConvertible {
  case cannotLoad(String)
  case differentSave(String)
  var description: String {
    switch self {
    case .cannotLoad(let name):
      return "Class \(name) cannot be loaded from its save"
    case .differentSave(let name):
      return "Class \(name) saves different data, than loaded"
    }
  }
}

public typealias SafeVersionable = SafeSerialization & Versionable

public protocol SafeSerialization {
  associatedtype DemoType: DataRepresentable
  static var safeDemo: DemoType { get }
}
open class SafeSerializationManager {
  public init() {}
  open func test() throws {
    
  }
  open func check<T: SafeSerialization>(_ type: T.Type) throws {
    let example = type.safeDemo
    var writer = DataWriter()
    writer.append(example)
    let firstSave = writer.data
    let reader = DataReader(data: firstSave)
    do {
      let loaded = try T.DemoType.init(data: reader)
      writer = DataWriter()
      writer.append(loaded)
      /// This one will fail on sets and dictionaries
      // if writer.data != firstSave {
      //   throw SafeVersionableError.differentSave(className(type))
      // }
    } catch SafeVersionableError.differentSave(let name) {
      throw SafeVersionableError.differentSave(name)
    } catch {
      throw SafeVersionableError.cannotLoad(className(type))
    }
  }
}
