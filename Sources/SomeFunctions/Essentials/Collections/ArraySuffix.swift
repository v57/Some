//
//  File.swift
//  
//
//  Created by Dmitry Kozlov on 7/26/20.
//

import Foundation

/// Represents array with unknown prefix
/// ArraySuffix([0,1,2,3,4], offset: 10)[11] will return 1
public struct ArraySuffix<T>: EasierCollection {
  public typealias Element = T
  public typealias SubSequence = ArraySlice<Element>
  
  public var array: [Element]
  public let offset: Int
  public init(_ array: [Element]) {
    self.array = array
    self.offset = 0
  }
  public init(_ array: [Element], offset: Int) {
    self.array = array
    self.offset = offset
  }
  public func convertIndex(_ index: Int) -> Int {
    index - offset
  }
}
extension ArraySuffix: ContiguousBytes where Element == UInt8 {
  public func withUnsafeBytes<R>(_ body: (UnsafeRawBufferPointer) throws -> R) rethrows -> R {
    try array.withUnsafeBytes(body)
  }
}
extension ArraySuffix: DataProtocol where Element == UInt8 {
  public typealias Regions = Array<Element>.Regions
  public var regions: Array<UInt8>.Regions {
    array.regions
  }
}
extension ArraySuffix: Equatable where Element: Equatable {}
extension ArraySuffix: Hashable where Element: Hashable {}
