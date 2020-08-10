//
//  ip.swift
//  Server
//
//  Created by Димасик on 3/24/17.
//
//

import Foundation

public var localhost = "127.0.0.1"

public struct IP {
  public var ip: String
  public var port: Int
  public var string: String { return "\(ip):\(port)" }
  
  #if os(macOS)
  public init?(string: String) {
    let split = string.components(separatedBy: ".")
    guard split.count == 4 else { return nil }
    guard let a0 = Int(split[0]) else { return nil }
    guard let a1 = Int(split[1]) else { return nil }
    guard let a2 = Int(split[2]) else { return nil }
    let s3 = split[3].components(separatedBy: ":")
    guard s3.count <= 2 else { return nil }
    guard let a3 = Int(s3[0]) else { return nil }

    ip = "\(a0).\(a1).\(a2).\(a3)"
    if s3.count == 2 {
      guard let p = Int(s3[1]) else { return nil }
      guard p < Int(Int16.max) else { return nil }
      port = p
    } else {
      port = 1989
    }
  }
  #endif
  
  public init(ip: String, port: Int) {
    self.ip = ip
    self.port = port
  }
  public init() {
    ip = "127.0.0.1"
    port = 80
  }
  
  #if os(macOS)
  @discardableResult
  public mutating func set(string: String) -> Bool {
    let split = string.components(separatedBy: ".")
    guard split.count == 4 else { return false }
    guard let a0 = Int(split[0]) else { return false }
    guard let a1 = Int(split[1]) else { return false }
    guard let a2 = Int(split[2]) else { return false }
    let s3 = split[3].components(separatedBy: ":")
    guard s3.count <= 2 else { return false }
    guard let a3 = Int(s3[0]) else { return false }
    
    ip = "\(a0).\(a1).\(a2).\(a3)"
    if s3.count == 2 {
      guard let p = Int(s3[1]) else { return false }
      guard p < Int(Int16.max) else { return false }
      port = p
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
  #endif
  public static var `public`: String? {
    guard let url = URL(string: "https://icanhazip.com/") else { return nil }
    let ip = try? String(contentsOf: url)
    return ip
  }
}
