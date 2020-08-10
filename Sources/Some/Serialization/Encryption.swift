
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

public protocol SomeSeedGenerator {
  func seed(_ x: UInt64, _ y: UInt64) -> UInt64
}

public protocol SomeSymmetricKey: SomeSeedGenerator {
  func encrypt(data: inout Data, salt: UInt64)
  func decrypt(data: inout Data, salt: UInt64)
}

extension SomeSymmetricKey {
  public func encrypt(data: inout Data, salt: UInt64 = 0xf85967b6a6d24cb4) {
    data.normalize(to: 8)
    let count = data.count / 8
    data.withUnsafeMutableBytes { data in
      let bytes = data.bindMemory(to: UInt64.self)
      for i in 0..<count {
        bytes[i] &+= self.seed(UInt64(i), salt)
      }
    }
  }
  public func decrypt(data: inout Data, salt: UInt64 = 0xf85967b6a6d24cb4) {
    data.normalize(to: 8)
    let count = data.count / 8
    data.withUnsafeMutableBytes { data in
      let bytes = data.bindMemory(to: UInt64.self)
      for i in 0..<count {
        bytes[i] &-= self.seed(UInt64(i), salt)
      }
    }
  }
}
public protocol SomeKeyHasher: SomeSeedGenerator {
  func hash(data: Data) -> UInt64
}
extension SomeKeyHasher {
  public func hash(data: Data) -> UInt64 {
    let data = data.normalized(to: 8)
    var hash: UInt64 = seed(0xf2e9a7004382af65,0x1435522785d4d67a)
    let chunks = data.count / 8
    data.withUnsafeBytes { data in
      let bytes = data.bindMemory(to: UInt64.self)
      for i in 0..<chunks {
        let value = bytes[i]
        self.hash(value: value, i: UInt64(i), hash: &hash)
      }
    }
    self.hash(value: UInt64(hash), i: UInt64(data.count), hash: &hash)
    return hash
  }
  private func hash(value: UInt64, i: UInt64, hash: inout UInt64) {
    if value == 0 {
      hash = hash &+ seed(UInt64(i), 0xb9c71519cf2bec49)
    } else {
      hash = hash &* value &+ value &+ seed(UInt64(i), 0xfd21fad96f215df)
    }
  }
}

public struct EncryptionKey: SomeSymmetricKey, SomeKeyHasher {
  public static var main = EncryptionKey(0xf5c3e0847eee6a63,0xd0a5261445f6e5f2,0x45b69c64d1cf2d5b,0x4f35b993a6fa4b1c)
  public let a: UInt64
  public let b: UInt64
  public let c: UInt64
  public let d: UInt64
  public var generator: Generator { Generator(key: self) }
  public init() {
    a = .random()
    b = .random()
    c = .random()
    d = .random()
  }
  public init(_ a: UInt64, _ b: UInt64, _ c: UInt64, _ d: UInt64) {
    self.a = a
    self.b = b
    self.c = c
    self.d = d
  }
  @inline(__always)
  public func seed(_ i: UInt64, _ e: UInt64 = 0xf539244bad9d0282) -> UInt64 {
    return (i &+ e) &* (i &* (i &+ d) &* a &+ b) &* c
  }
  public struct Generator: RandomNumberGenerator {
    public static var main = EncryptionKey.main.generator
    var key: EncryptionKey
    var i: UInt64 = 0
    mutating public func next() -> UInt64 {
      defer { i += 1 }
      return key.seed(i, 0xa34ae8a5cd3e61a6)
    }
  }
}

extension MutableCollection where Iterator.Element == UInt8, Index == Int {
  public mutating func encrypt(password: UInt64, offset: Int = 0) {
    guard count > 0 else { return }
    for i in 0..<count {
      let v = UInt64.seed(password, UInt64(i+offset))
      let b = UInt8(v & 0xFF)
      self[i] = self[i] &+ b
    }
  }
  public mutating func decrypt(password: UInt64, offset: Int = 0) {
    guard count > 0 else { return }
    for i in 0..<count {
      let v = UInt64.seed(password, UInt64(i+offset))
      let b = UInt8(v & 0xFF)
      self[i] = self[i] &- b
    }
  }
}

extension String {
  public var hash64: UInt64 {
    return EncryptionKey.main.hash(data: data)
  }
}
extension Data {
  public var hash64: UInt64 {
    return EncryptionKey.main.hash(data: data)
  }
}
public struct SafeHash<Hash,Value> where Hash: Hashable, Value: LosslessDataConvertible {
  public var values = [Hash: Value]()
  public mutating func insert(hash: Hash, value: Value) {
    if let oldValue = values[hash] {
      fatalError("""
        Hash collision detected
        \(value) and \(oldValue)
        has the same hash: \(hash)
        
        all data: \(values)
        """)
    } else {
      values[hash] = value
    }
  }
}

extension Data {
  public mutating func encrypt(password: UInt64, from: Int) {
    //    print("encrypting \(hex)\n with \(password), from: \(from)")
    let count = self.count
    withUnsafeMutableBytes { bytes in
      for i in from..<count {
        let v = UInt64.seed(password, UInt64(i))
        let b = UInt8(v & 0xFF)
        bytes[i] = bytes[i] &+ b
      }
    }
  }
  public mutating func decrypt(password: UInt64, from: Int) {
    //    print("decrypting \(hex)\n with \(password), from: \(from)")
    let count = self.count
    withUnsafeMutableBytes { bytes in
      for i in from..<count {
        let v = UInt64.seed(password, UInt64(i))
        let b = UInt8(v & 0xFF)
        bytes[i] = bytes[i] &- b
      }
    }
  }
  public mutating func encrypt(password: UInt64, offset: Int = 0) {
    //    print("encrypting \(hex)\n with \(password), offset: \(offset)")
    let count = self.count
    withUnsafeMutableBytes { bytes in
      for i in 0..<count {
        let v = UInt64.seed(password, UInt64(i+offset))
        let b = UInt8(v & 0xFF)
        bytes[i] = bytes[i] &+ b
      }
    }
  }
  public mutating func decrypt(password: UInt64, offset: Int = 0) {
    //    print("decrypting \(hex)\n with \(password), offset: \(offset)")
    let count = self.count
    withUnsafeMutableBytes { bytes in
      for i in 0..<count {
        let v = UInt64.seed(password, UInt64(i+offset))
        let b = UInt8(v & 0xFF)
        bytes[i] = bytes[i] &- b
      }
    }
  }
}


public extension DataReader {
  func decrypt(password: UInt64, offset: Int) {
    data.decrypt(password: password, offset: offset)
  }
  func decrypt(password: UInt64) {
    data.decrypt(password: password, from: position)
  }
  func decrypt(using key: SomeSymmetricKey, password: UInt64) {
    key.decrypt(data: &data, salt: password)
  }
}

public extension DataWriter {
  func encrypt(password: UInt64, from: Int) {
    data.encrypt(password: password, from: from)
  }
  func encrypt(password: UInt64, offset: Int = 0) {
    data.encrypt(password: password, offset: offset)
  }
  func encrypt(using key: SomeSymmetricKey, password: UInt64) {
    key.encrypt(data: &data, salt: password)
  }
}
