//
//  DataWriter.swift
//  Some
//
//  Created by Димасик on 12/13/17.
//  Copyright © 2017 Dmitry Kozlov. All rights reserved.
//

import Foundation

public struct WriterPointer<T: FixedWidth> {
  public let data: DataWriter
  public let position: Int
  public init(_ data: DataWriter) {
    self.data = data
    position = data.count
    data.data.append(T())
  }
  public func set(_ value: T) {
    data.data.replace(at: position, with: value)
  }
}

public class DataWriter: DataRepresentable {
  public var data: Data
  public var count: Int { data.count }
  public var isEmpty: Bool { data.isEmpty }
  public var base64: String { data.base64EncodedString() }
  public var compress = true
  public init(data: Data) {
    self.data = data
  }
  public init() {
    data = Data()
  }
  public required init(data: DataReader) throws {
    self.data = try data.next()
  }
  public func save(data: DataWriter) {
    data.append(self.data)
  }
  public func copy() -> DataWriter {
    return DataWriter(data: data.copy())
  }
  public func uncompressed(_ action: ()->()) {
    let compress = self.compress
    self.compress = false
    defer { self.compress = compress }
    action()
  }
  
  public func replace(at index: Int, with data: Data) {
    self.data.replaceSubrange(index..<index+data.count, with: data)
  }
  
  public func append(_ value: DataEncodable) {
    value.save(data: self)
  }
  public func append(_ value: DataEncodableVersionable, version: Int) {
    value.save(data: self, version: version)
  }
  public func append<T: DataEncodableVersionable & Versionable>(_ value: T, _ version: DataVersion) {
    value.save(data: self, version: version.version(for: T.self))
  }
  public func append(_ value: DataEncodableVersionable?, version: Int) {
    append(value != nil)
    value?.save(data: self, version: version)
  }
  public func append<T: DataEncodableVersionable & Versionable>(_ value: T?, _ version: DataVersion) {
    append(value != nil)
    value?.save(data: self, version: version.version(for: T.self))
  }
  
  //  // Number
  //  public func append<T: DataRepresentable>(_ value: T...) {
  //    value.forEach { $0.write(to: &data) }
  //  }
  
  // [Number]
  //  public func append<T>(_ value: Array<T>) where T: DataRepresentable {
  //    var value = value
  //    append(value.count)
  //    if compress {
  //      for v in value {
  //        v.save(data: self)
  //      }
  //    } else {
  //      data.append(UnsafeBufferPointer(start: &value, count: value.count))
  //    }
  //  }
  //  public func append<T>(_ value: Set<T>) where T: DataRepresentable {
  //    var value = value
  //    append(value.count)
  //    if compress {
  //      for v in value {
  //        v.write(to: &data)
  //      }
  //    } else {
  //      data.append(UnsafeBufferPointer(start: &value, count: value.count))
  //    }
  //  }
  //  public func append<T>(_ value: ArraySlice<T>) where T: DataRepresentable {
  //    var value = value
  //    append(value.count)
  //    if compress {
  //      for v in value {
  //        v.write(to: &data)
  //      }
  //    } else {
  //      data.append(UnsafeBufferPointer(start: &value, count: value.count))
  //    }
  //  }
  //  public func append(_ value: DataEncodable?) {
  //    append(value != nil)
  //    guard let value = value else { return }
  //    value.save(data: self)
  //  }
  //  // [Data]
  //  public func append<T>(_ value: Array<T>) where T: DataEncodable {
  //    append(value.count)
  //    value.forEach {
  //      append($0)
  //    }
  //  }
  //  public func append<T>(_ value: Set<T>) where T: DataEncodable {
  //    append(value.count)
  //    value.forEach {
  //      append($0)
  //    }
  //  }
}

#if os(iOS)
extension SomeSettings {
  public static var dataWriterProtection = false
}

public extension DataWriter {
  func write(to url: FileURL) throws {
    if SomeSettings.dataWriterProtection {
      try data.write(to: url.url, options: .completeFileProtection)
    } else {
      try data.write(to: url)
    }
  }
}
#else
public extension DataWriter {
  func write(to url: FileURL) throws {
    try data.write(to: url)
  }
}
#endif
