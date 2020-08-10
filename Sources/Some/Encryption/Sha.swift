//
//  File.swift
//  
//
//  Created by Dmitry Kozlov on 8/10/20.
//

import Foundation
import SomeC

public extension Data {
  /// - Returns: sha256 hash of data
  var sha256: Data {
    var data = Data(count: 32)
    SHA256_Buf(baseAddress8, count, data.mutableBaseAddress8)
    return data
  }
}

