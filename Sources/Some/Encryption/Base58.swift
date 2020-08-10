//
//  Base58.swift
//  web3swift
//
//  Created by Alexander Vlasov on 10.01.2018.
//  Copyright © 2018 Bankex Foundation. All rights reserved.
//

import Foundation
import SomeC

public enum Base58Alphabet: Int8 {
  case bitcoin, ripple
}

public enum Base58Error: Error {
  case invalidStringFormat
  case invalidPrefix
  case invalidChecksum
  case invalidSize
}


public extension Data {
  func base58(_ alphabet: Base58Alphabet) -> String {
    var size = count*2
    var data = Data(count: size)
    b58enc(data.mutableVoidPointer, &size, self.baseAddress, count, alphabet.rawValue)
    return String(data: data[..<size], encoding: .utf8)!
  }
  func base58(_ alphabet: Base58Alphabet, prefix: UInt8) -> String {
    return base58Check(alphabet,prefix).base58(alphabet)
  }
  func base58Check(_ alphabet: Base58Alphabet, _ prefix: UInt8) -> Data {
    var data = self
    data.reserveCapacity(data.count + 5)
    data.insert(prefix, at: 0)
    data.append(data.sha256.sha256[0..<4])
    return data
  }
}

public extension String {
  func base58(_ alphabet: Base58Alphabet) throws -> Data {
    guard !isEmpty else { throw Base58Error.invalidSize }
    let data = Data(utf8)
    var result = Data(count: count)
    var size = count
    guard b58tobin(result.mutableBaseAddress, &size, data.voidPointer, data.count, alphabet.rawValue)
      else { throw Base58Error.invalidStringFormat }
    return result.subdata(in: count-size..<count)
  }
  func base58(_ alphabet: Base58Alphabet, check: Bool, prefix: UInt8? = nil) throws -> Data {
    let data = try base58(alphabet)
    
    // There should be at least one byte between 1 byte prefix and 4 byte checksum
    guard data.count > 5 else { throw Base58Error.invalidSize }
    let checksumIndex = data.count-4
    if let prefix = prefix {
      guard data[0] == prefix else { throw Base58Error.invalidPrefix }
    }
    if check {
      guard data[checksumIndex...] == data[..<checksumIndex].sha256.sha256[..<4]
        else { throw Base58Error.invalidChecksum }
    }
    return data[1..<checksumIndex]
  }
}
