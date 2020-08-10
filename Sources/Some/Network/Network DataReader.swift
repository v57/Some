//
//  DataReader.swift
//  Network
//
//  Created by Димасик on 9/20/17.
//  Copyright © 2017 Dmitry Kozlov. All rights reserved.
//

#if !os(Linux)
import Foundation

extension DataReader {
  func has(unusedBytes: Int) -> Bool {
    return count - position >= unusedBytes
  }
  func removeUsedBytes() {
    guard position > 0 else { return }
    data.removeSubrange(0..<position)
    position = 0
  }
  var packageSize: UInt32 {
    let start = position
    let end = position + 4
    guard end <= count else { return 0 }
    let slice = data[start..<end]
    return slice.convert()
  }
  
  func package() throws -> DataReader? {
    let packageSize = self.packageSize
    guard packageSize > 0 else { return nil }
    guard position + Int(packageSize) <= count else { return nil }
    
    position += 4
    let length = Int(packageSize) - 4
    let start = position
    let end = position + length
    guard end <= count else { throw corrupted }
    position = end
    let slice = data.subdata(in: start..<end)
    let reader = DataReader(data: slice)
    return reader
  }
}
#endif
