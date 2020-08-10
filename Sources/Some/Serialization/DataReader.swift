//
//  DataReader.swift
//  Some
//
//  Created by Димасик on 12/13/17.
//  Copyright © 2017 Dmitry Kozlov. All rights reserved.
//

import Foundation

public enum DataOptions {
  // write/read
  case compress
  // read
  case preview
}
open class DataReader: DataRepresentable {
  public var data: Data {
    didSet {
      pointer = data.withUnsafeBytes { $0.baseAddress! }
    }
  }
  public private(set) var pointer: UnsafeRawPointer
  public var position = 0
  public var count: Int { data.count }
  public var isEmpty: Bool { data.isEmpty }
  public var bytesLeft: Int { count - position }
  public var compress = true
  public var preview = false
  public var safeLimits = 1000000
  public init() {
    self.data = Data()
    self.pointer = data.withUnsafeBytes { $0.baseAddress! }
  }
  public init(data: Data) {
    self.data = data
    self.pointer = data.withUnsafeBytes { $0.baseAddress! }
  }
  public required init(data: DataReader) throws {
    self.data = try data.next()
    self.pointer = self.data.withUnsafeBytes { $0.baseAddress! }
  }
  public init?(base64: String) {
    guard let data = Data(base64Encoded: base64) else { return nil }
    self.data = data
    self.pointer = data.withUnsafeBytes { $0.baseAddress! }
  }
  public init?(url: FileURL) {
    if let data = Data(contentsOf: url) {
      self.data = data
      self.pointer = data.withUnsafeBytes { $0.baseAddress! }
    } else {
      return nil
    }
  }
}

// MARK: Reading
public extension DataReader {
  func offset(by offset: Int) throws -> Range<Int> {
    let start = position
    let end = position + offset
    guard end <= data.count else { throw corrupted }
    if !preview {
      position = end
    }
    return start..<end
  }
  // func pointee<T>() throws -> T {
  //   
  //   pointer.load(fromByteOffset: position, as: <#T##T.Type#>)
  // }
  
  func uncompressed(_ action: ()->()) {
    let compress = self.compress
    self.compress = false
    defer { self.compress = compress }
    action()
  }
  func offset(_ position: Int) -> Self {
    self.position += position
    return self
  }
  func save(data: DataWriter) {
    data.append(self.data)
  }
  func convert<T>() throws -> T where T: DataRepresentable {
    return try subdata(MemoryLayout<T>.size).convert()
  }
  func check(count: Int, max: Int) throws {
    guard count <= bytesLeft else { throw corrupted }
    guard count >= 0 else { throw corrupted }
    guard count < max else { throw corrupted }
  }
  
  func next<T>() throws -> T where T: DataDecodable {
    try T.init(data: self)
  }
  func next<T>(version: Int) throws -> T where T: DataDecodableVersionable {
    try T.init(data: self, version: version)
  }
  func next<T>(_ version: DataVersion) throws -> T where T: DataDecodableVersionable & Versionable {
    try T.init(data: self, version: version.version(for: T.self))
  }
  func next<T>(version: Int) throws -> T? where T: DataDecodableVersionable {
    guard try bool() else { return nil }
    return try T.init(data: self, version: version)
  }
  func next<T>(_ version: DataVersion) throws -> T? where T: DataDecodableVersionable & Versionable {
    guard try bool() else { return nil }
    return try T.init(data: self, version: version.version(for: T.self))
  }
  #if !__LP64__
  func next() throws -> [Int] {
    let array: [Int64] = try next()
    return array.map { Int($0) }
  }
  func next() throws -> [UInt] {
    let array: [UInt64] = try next()
    return array.map { UInt($0) }
  }
  #endif
  
  func load<T>(_ value: T) throws where T: DataLoadable {
    return try value.load(data: self)
  }
  func load<T>(_ value: Array<T>) throws where T: DataLoadable {
    for v in value {
      try v.load(data: self)
    }
  }
  func load<T>(_ value: Set<T>) throws where T: DataLoadable {
    for v in value {
      try v.load(data: self)
    }
  }
  
  func update<T>(_ value: Array<T>) where T: DataLoadable {
    for v in value {
      try? v.load(data: self)
    }
  }
  func update<T>(_ value: Set<T>) where T: DataLoadable {
    for v in value {
      try? v.load(data: self)
    }
  }
  func update<T>(_ value: ArraySlice<T>) where T: DataLoadable {
    for v in value {
      try? v.load(data: self)
    }
  }
  func subdata(_ count: Int) throws -> Data {
    guard position + count <= data.count else { throw corrupted }
    let subdata = data.subdata(in: position..<position+count)
    if !preview {
      position += count
    }
    return subdata
  }
  
  // долбаеб не используй это вместо int() только для того,
  // чтобы получить положительное число
  func intCount() throws -> Int {
    let count = try int()
    try check(count: count, max: safeLimits)
    return count
  }
  func intCount(max: Int) throws -> Int {
    let count = try int()
    try check(count: count, max: max)
    return count
  }
  func `enum`<T,S>() throws -> T where T: RawRepresentable, S: DataRepresentable, T.RawValue == S {
    return try next()
  }
  func uint() throws -> UInt {
    return try next()
  }
  func uint64() throws -> UInt64 {
    return try next()
  }
  func uint32() throws -> UInt32 {
    return try next()
  }
  func uint16() throws -> UInt16 {
    return try next()
  }
  func uint8() throws -> UInt8 {
    return try next()
  }
  func int() throws -> Int {
    return try next()
  }
  func int64() throws -> Int64 {
    return try next()
  }
  func int32() throws -> Int32 {
    return try next()
  }
  func int16() throws -> Int16 {
    return try next()
  }
  func int8() throws -> Int8 {
    return try next()
  }
  func string() throws -> String {
    return try next()
  }
  func bool() throws -> Bool {
    return try next()
  }
  func float() throws -> Float {
    return try next()
  }
  func double() throws -> Double {
    return try next()
  }
  
  func uintArray() throws -> Array<UInt> {
    return try next()
  }
  func uint64Array() throws -> Array<UInt64> {
    return try next()
  }
  func uint32Array() throws -> Array<UInt32> {
    return try next()
  }
  func uint16Array() throws -> Array<UInt16> {
    return try next()
  }
  func uint8Array() throws -> Array<UInt8> {
    return try next()
  }
  func intArray() throws -> Array<Int> {
    return try next()
  }
  func int64Array() throws -> Array<Int64> {
    return try next()
  }
  func int32Array() throws -> Array<Int32> {
    return try next()
  }
  func int16Array() throws -> Array<Int16> {
    return try next()
  }
  func int8Array() throws -> Array<Int8> {
    return try next()
  }
  func stringArray() throws -> Array<String> {
    return try next()
  }
  
  func uintSet() throws -> Set<UInt> {
    return try next()
  }
  func uint64Set() throws -> Set<UInt64> {
    return try next()
  }
  func uint32Set() throws -> Set<UInt32> {
    return try next()
  }
  func uint16Set() throws -> Set<UInt16> {
    return try next()
  }
  func uint8Set() throws -> Set<UInt8> {
    return try next()
  }
  func intSet() throws -> Set<Int> {
    return try next()
  }
  func int64Set() throws -> Set<Int64> {
    return try next()
  }
  func int32Set() throws -> Set<Int32> {
    return try next()
  }
  func int16Set() throws -> Set<Int16> {
    return try next()
  }
  func int8Set() throws -> Set<Int8> {
    return try next()
  }
  func stringSet() throws -> Set<String> {
    return try next()
  }
  
  
  func uintFull() throws -> UInt {
    return try convert()
  }
  func uint64Full() throws -> UInt64 {
    return try convert()
  }
  func uint32Full() throws -> UInt32 {
    return try convert()
  }
  func intFull() throws -> Int {
    return try convert()
  }
  func int64Full() throws -> Int64 {
    return try convert()
  }
  func int32Full() throws -> Int32 {
    return try convert()
  }
  //  func next<T,S>() throws -> T where T: RawRepresentable, S: DataRepresentable, T.RawValue == S {
  //
  //  }
  //  func next<T>() throws -> T where T: DataRepresentable {
  //
  //  }
}

extension DataReader: CustomStringConvertible {
  public var description: String {
    var string = "DataReader \(position)/\(count)"
    let first = min(16,count)
    let last = max(count-16,0)
    let previous = max(position-16,0)
    let next = min(position+16,count)
    
    string.addLine("first: \(data[0..<first].hex(separateEvery: 4, separator: " "))")
    string.addLine("last: \(data[last..<count].hex(separateEvery: 4, separator: " "))")
    string.addLine("previous: \(data[previous..<position].hex(separateEvery: 4, separator: " "))")
    string.addLine("next: \(data[position..<next].hex(separateEvery: 4, separator: " "))")
    
    return string
  }
}
