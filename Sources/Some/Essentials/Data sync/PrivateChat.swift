//
//  File.swift
//  
//
//  Created by Dmitry Kozlov on 9/2/20.
//

import Foundation

public struct PrivateChatUser: ComparsionValue {
  public var id: Int
  public var lastRead: Int
  public var _valueToCompare: Int { id }
}
extension PrivateChatUser: Equatable {
  public static func ==(l: Self, r: Self) -> Bool {
    l.id == r.id
  }
}
