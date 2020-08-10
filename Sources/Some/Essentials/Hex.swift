//
//  Hex.swift
//  DefinitionsParser
//
//  Created by Dmitry on 15/01/2019.
//  Copyright © 2019 Bankex Foundation. All rights reserved.
//

import Foundation

/// Hex errors
public enum HexError: Error {
  /// Throws if data cannot be converted to string
  case invalidHexFormat(String)
  /// Printable / user displayable description
  public var localizedDescription: String {
    switch self {
    case let .invalidHexFormat(string):
      return "Cannot convert hex string \"\(string)\" to data"
    }
  }
}
public extension Data {
  /// Returns Hex representation of data
  var hex: String {
    var data = Data(count: count*2)
    hexMap.withUnsafeBytes { ptr in
      let ptr = ptr.baseAddress!
        .advanced(by: 512)
        .assumingMemoryBound(to: UInt16.self)
      data.withUnsafeMutableBytes {
        let p = $0.bindMemory(to: UInt16.self)
        withUnsafeBytes { b in
          for i in 0..<count {
            p[i] = ptr[Int(b[i])]
          }
        }
      }
    }
    return String(data: data, encoding: .utf8)!
  }
  
  /// - Parameter separateEvery: Position where separator should be inserted.
  /// Counts per byte (not per character)
  /// - Parameter separator: Separator string
  /// - Returns: Hex representation of data
  func hex(separateEvery: Int, separator: String) -> String {
    let separatorData = separator.data(using: .utf8)!
    let separatorSize = separatorData.count
    
    let separations = ((count-1) / separateEvery) * separatorSize
    let stringSize = (count*2) + separations * separatorSize
    
    let stringPointer = malloc(stringSize)!
    
    var byteIndex = 0
    var stringIndex = 0
    var iteration = 0
    hexMap.withUnsafeBytes { hexMapPointer in
      let hexMapPointer = hexMapPointer.baseAddress!.advanced(by: 512)
    withUnsafeBytes { input in
      separatorData.withUnsafeBytes { separatorPointer in
        while byteIndex < count {
          if (iteration + 1) % (separateEvery + 1) == 0 {
            (stringPointer + stringIndex)
              .copyMemory(from: separatorPointer.baseAddress!, byteCount: separatorSize)
            stringIndex += separatorSize
          } else {
            (stringPointer + stringIndex)
              .copyMemory(from: hexMapPointer + Int(input[byteIndex]) * 2, byteCount: 2)
            stringIndex += 2
            byteIndex += 1
          }
          iteration += 1
        }
      }}}
    return String(bytesNoCopy: stringPointer, length: stringSize, encoding: .utf8, freeWhenDone: true)!
  }
  var string: String {
    return String(data: self, encoding: .utf8)!
  }
}

public extension String {
  var isHex: Bool {
    // string•UInt16.self == 0x7830
    // is actually slower than hasPrefix("0x")
    // because of optimisations
    return hasPrefix("0x")
  }
  var withHex: String {
    return isHex ? self : "0x" + self
  }
  var withoutHex: String {
    return isHex ? String(dropFirst(2)) : self
  }
  func dataFromHex() throws -> Data {
    let string: [UInt8] = Array(utf8)
    var count = string.count / 2
    var index = 0
    if isHex {
      count -= 1
      index += 2
    }
    var cIndex = 0
    
    var data = Data(count: count)
    try hexMap.withUnsafeBytes { hexMap in
      let leftMap = hexMap.baseAddress!.assumingMemoryBound(to: UInt8.self)
      let rightMap = hexMap.baseAddress!.advanced(by: 256).assumingMemoryBound(to: UInt8.self)
      try data.withUnsafeMutableBytes { output in
        while cIndex < count {
          if index + 1 < string.count {
            let a = rightMap[Int(string[index])]
            guard a != 1 else { throw HexError.invalidHexFormat(self) }
            let b = leftMap[Int(string[index+1])]
            guard b != 16 else { throw HexError.invalidHexFormat(self) }
            output[cIndex] = a | b
            index += 2
            cIndex += 1
          } else {
            let a = leftMap[Int(string[index])]
            guard a != 16 else { throw HexError.invalidHexFormat(self) }
            output[cIndex] = a
            break
          }
        }
      }
    }
    return data
  }
  /// Returns data from hex string
  var hex: Data {
    return (try? dataFromHex()) ?? Data()
  }
  
  /// - Returns: Hex representation of data
  func hex(separateEvery: Int, separator: String) throws -> Data {
    let separatorSize = separator.utf8.count
    let string: [UInt8] = Array(utf8)
    
    let separations = string.count / (separateEvery * 2 + separatorSize)
    let bytesCount = (string.count - (separations * separatorSize)) / 2
    
    var data = Data(count: bytesCount)
    var characterIndex = 0
    var dataIndex = 0
    var iteraction = 0
    
    try hexMap.withUnsafeBytes { hexMap in
      let leftMap = hexMap.baseAddress!.assumingMemoryBound(to: UInt8.self)
      let rightMap = hexMap.baseAddress!.advanced(by: 256).assumingMemoryBound(to: UInt8.self)
      try data.withUnsafeMutableBytes { output in
        while dataIndex < bytesCount {
          if (iteraction + 1) % (separateEvery + 1) == 0 {
            characterIndex += separatorSize
          } else {
            if characterIndex + 1 < string.count {
              let a = rightMap[Int(string[characterIndex])]
              guard a != 1 else { throw HexError.invalidHexFormat(self) }
              let b = leftMap[Int(string[characterIndex+1])]
              guard b != 16 else { throw HexError.invalidHexFormat(self) }
              output[dataIndex] = a | b
              characterIndex += 2
              dataIndex += 1
            } else {
              let a = leftMap[Int(string[characterIndex])]
              guard a != 16 else { throw HexError.invalidHexFormat(self) }
              output[dataIndex] = a
              break
            }
          }
          iteraction += 1
        }
      }
    }
    return data
  }
}

extension BinaryInteger {
  public var hex: String {
    return hex(withPrefix: true, padded: false)
  }
  public func hex(withPrefix: Bool, padded: Bool) -> String {
    var hex = String(magnitude, radix: 16)
    if padded {
      hex = String(repeating: "0", count: MemoryLayout<Self>.size * 2 - hex.count) + hex
    }
    return withPrefix ? "0x" + hex : hex
  }
}

private let hexMap: [UInt64] = [
  0x1010101010101010, 0x1010101010101010, 0x1010101010101010, 0x1010101010101010,
  0x1010101010101010, 0x1010101010101010, 0x0706050403020100, 0x1010101010100908,
  0x100f0e0d0c0b0a10, 0x1010101010101010, 0x1010101010101010, 0x1010101010101010,
  0x100f0e0d0c0b0a10, 0x1010101010101010, 0x1010101010101010, 0x1010101010101010,
  0x1010101010101010, 0x1010101010101010, 0x1010101010101010, 0x1010101010101010,
  0x1010101010101010, 0x1010101010101010, 0x1010101010101010, 0x1010101010101010,
  0x1010101010101010, 0x1010101010101010, 0x1010101010101010, 0x1010101010101010,
  0x1010101010101010, 0x1010101010101010, 0x1010101010101010, 0x1010101010101010,
  0x0101010101010101, 0x0101010101010101, 0x0101010101010101, 0x0101010101010101,
  0x0101010101010101, 0x0101010101010101, 0x7060504030201000, 0x0101010101019080,
  0x01f0e0d0c0b0a001, 0x0101010101010101, 0x0101010101010101, 0x0101010101010101,
  0x01f0e0d0c0b0a001, 0x0101010101010101, 0x0101010101010101, 0x0101010101010101,
  0x0101010101010101, 0x0101010101010101, 0x0101010101010101, 0x0101010101010101,
  0x0101010101010101, 0x0101010101010101, 0x0101010101010101, 0x0101010101010101,
  0x0101010101010101, 0x0101010101010101, 0x0101010101010101, 0x0101010101010101,
  0x0101010101010101, 0x0101010101010101, 0x0101010101010101, 0x0101010101010101,
  0x3330323031303030, 0x3730363035303430, 0x6230613039303830, 0x6630653064306330,
  0x3331323131313031, 0x3731363135313431, 0x6231613139313831, 0x6631653164316331,
  0x3332323231323032, 0x3732363235323432, 0x6232613239323832, 0x6632653264326332,
  0x3333323331333033, 0x3733363335333433, 0x6233613339333833, 0x6633653364336333,
  0x3334323431343034, 0x3734363435343434, 0x6234613439343834, 0x6634653464346334,
  0x3335323531353035, 0x3735363535353435, 0x6235613539353835, 0x6635653564356335,
  0x3336323631363036, 0x3736363635363436, 0x6236613639363836, 0x6636653664366336,
  0x3337323731373037, 0x3737363735373437, 0x6237613739373837, 0x6637653764376337,
  0x3338323831383038, 0x3738363835383438, 0x6238613839383838, 0x6638653864386338,
  0x3339323931393039, 0x3739363935393439, 0x6239613939393839, 0x6639653964396339,
  0x3361326131613061, 0x3761366135613461, 0x6261616139613861, 0x6661656164616361,
  0x3362326231623062, 0x3762366235623462, 0x6262616239623862, 0x6662656264626362,
  0x3363326331633063, 0x3763366335633463, 0x6263616339633863, 0x6663656364636363,
  0x3364326431643064, 0x3764366435643464, 0x6264616439643864, 0x6664656464646364,
  0x3365326531653065, 0x3765366535653465, 0x6265616539653865, 0x6665656564656365,
  0x3366326631663066, 0x3766366635663466, 0x6266616639663866, 0x6666656664666366]
