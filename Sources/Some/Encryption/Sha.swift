//
//  File.swift
//  
//
//  Created by Dmitry Kozlov on 8/10/20.
//

import Foundation
import SomeC

#if os(iOS)
import CryptoKit
public extension Sequence where Element == Data {
  var sha256: Data {
    if #available(iOS 13.0, *) {
      var sha = SHA256()
      forEach { sha.update(data: $0) }
      return sha.finalize().data
    } else {
      var data = Data(count: 32)
      var ctx = SomeC_SHA256_CTX()
      SomeC_SHA256_Init(&ctx)
      forEach { data in
        data.withUnsafeBytes { p in
          SomeC_SHA256_Update(&ctx, p.baseAddress!, p.count)
        }
      }
      data.withUnsafeMutableBytes { p in
        SomeC_SHA256_Final(p.baseAddress!, &ctx)
      }
      return data
    }
  }
}
public extension FileURL {
  /// Returns sha256 file. On iOS 13.4 will return nil if file is greater than 50mb
  var sha256: Data? {
    guard #available(iOS 13.4, *) else {
      return self.fileSize < 50.mb ? data?.sha256 : nil
    }
    var sha = SHA256()
    do {
      let handle = try FileHandle(forReadingFrom: url)
      var running = true
      while running {
        try autoreleasepool {
          guard let data = try handle.read(upToCount: 1.mb) else {
            running = false
            return }
          sha.update(data: data)
        }
      }
      return sha.finalize().data
    } catch {
      return nil
    }
  }
}
#endif

public extension Data {
  // /// - Returns: kaccak256 hash of data
  // var keccak256: Data {
  //   var data = Data(count: 32)
  //   keccak_256(data.mutableBaseAddress8, 32, baseAddress8, count)
  //   return data
  // }
  /// - Returns: sha256 hash of data
  var sha256: Data {
    #if os(iOS)
    if #available(iOS 13.0, *) {
      var sha = SHA256()
      sha.update(data: self)
      return sha.finalize().data
    } else {
      var data = Data(count: 32)
      SomeC_SHA256_Buf(baseAddress8, count, data.mutableBaseAddress8)
      return data
    }
    #else
    var data = Data(count: 32)
    SomeC_SHA256_Buf(baseAddress8, count, data.mutableBaseAddress8)
    return data
    #endif
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
public extension String {
  var sha256: Data { data.sha256 }
}


