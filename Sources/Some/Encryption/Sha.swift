//
//  File.swift
//  
//
//  Created by Dmitry Kozlov on 8/10/20.
//

import Foundation
import SomeC

public extension Data {
  // /// - Returns: kaccak256 hash of data
  // var keccak256: Data {
  //   var data = Data(count: 32)
  //   keccak_256(data.mutableBaseAddress8, 32, baseAddress8, count)
  //   return data
  // }
  /// - Returns: sha256 hash of data
  var sha256: Data {
    var data = Data(count: 32)
    SomeC_SHA256_Buf(baseAddress8, count, data.mutableBaseAddress8)
    return data
  }
  var uint64: UInt64 {
    var number = UInt64()
    self.withUnsafeBytes { data in
      Swift.withUnsafeMutableBytes(of: &number) {
        $0.safeCopyMemory(from: data)
      }
    }
    return number
  }
}

