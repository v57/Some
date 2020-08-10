//
//  File.swift
//  
//
//  Created by Dmitry Kozlov on 8/9/20.
//

import Foundation

extension UnsafeRawPointer {
  func load<T>(offset: inout Int, count: Int, as: T.Type) throws -> T {
    let size = MemoryLayout<T>.stride
    guard offset + size <= count else { throw corrupted }
    let v = advanced(by: offset).bindMemory(to: T.self, capacity: 1).pointee
    offset += size
    return v
  }
}
