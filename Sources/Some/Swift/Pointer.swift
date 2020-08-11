//
//  File.swift
//  
//
//  Created by Dmitry Kozlov on 8/9/20.
//

import Foundation

public extension UnsafeRawPointer {
  func load<T>(offset: inout Int, count: Int, as: T.Type) throws -> T {
    let size = MemoryLayout<T>.stride
    guard offset + size <= count else { throw corrupted }
    let v = advanced(by: offset).bindMemory(to: T.self, capacity: 1).pointee
    offset += size
    return v
  }
}
public extension UnsafeMutableRawBufferPointer {
  /// Safely copies memory so it won't overlaps like in `.copyMemory` function
  @inlinable
  func safeCopyMemory(from source: UnsafeRawBufferPointer) {
    baseAddress!.copyMemory(from: source.baseAddress!, byteCount: Swift.min(count, source.count))
  }
}

