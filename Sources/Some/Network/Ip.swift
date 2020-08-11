//
//  ip.swift
//  Server
//
//  Created by Димасик on 3/24/17.
//
//

import Foundation

public var localhost = "127.0.0.1"

public struct IP: ExpressibleByStringLiteral, ExpressibleByIntegerLiteral, CustomStringConvertible {
  public var ip: String
  public var port: Int
  public var string: String { return "\(ip):\(port)" }
  
  public init(stringLiteral value: String) {
    self.init(value)!
  }
  public init(integerLiteral value: Int) {
    self.init(ip: "0.0.0.0", port: value)
  }
  public init?(_ string: String) {
    let ipPort = string.components(separatedBy: ":")
    guard ipPort.count > 0 && ipPort.count < 3 else { return nil }
    guard ipPort[0]
      .components(separatedBy: ".")
      .compactMap(UInt8.init).count == 4 else { return nil }
    ip = String(ipPort[0])
    if ipPort.count == 2 {
      guard let p = Int(ipPort[1]) else { return nil }
      guard p < Int(Int16.max) else { return nil }
      port = p
    } else {
      port = 1989
    }
  }
  
  public init(ip: String, port: Int) {
    self.ip = ip
    self.port = port
  }
  public init() {
    ip = "127.0.0.1"
    port = 80
  }
  public static var `public`: String? {
    guard let url = URL(string: "https://icanhazip.com/") else { return nil }
    let ip = try? String(contentsOf: url)
    return ip
  }
  public var description: String { string }
}


#if os(macOS) || os(Linux)
extension IP {
  @discardableResult
  public mutating func set(string: String) -> Bool {
    let ipPort = string.components(separatedBy: ":")
    guard ipPort.count > 0 && ipPort.count < 3 else { return false }
    guard ipPort[0]
      .components(separatedBy: ".")
      .compactMap(UInt8.init).count == 4 else { return false }
    ip = String(ipPort[0])
    if ipPort.count == 2 {
      guard let p = Int(ipPort[1]), p < Int(Int16.max) else { return false }
      guard p < Int(Int16.max) else { return false }
      port = p
    } else {
      port = 1989
    }
    return true
  }
  
  public static var wifi: String? {
    for address in Host.current().addresses {
      guard address.count < 16 else { continue } // skipping ipv6
      guard address != localhost else { return nil }
      return address
    }
    return nil
  }
}
#endif

