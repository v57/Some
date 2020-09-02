//
//  File.swift
//  
//
//  Created by Dmitry Kozlov on 9/2/20.
//

import Foundation

public protocol ArraySyncGroupChat: ReadableChat {
  associatedtype Users: Collection where Users.Element == ChatUser
  var participants: Users { get }
  func user(for id: Int) -> ChatUser?
  func editUser(for id: Int, edit: (inout ChatUser) -> ())
}
public extension ArraySyncGroupChat {
  
}
