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
public protocol ASPrivateChat: ArraySyncChat {
  var users: Vector2<PrivateChatUser> { get set }
  func recipientDidRead(user: PrivateChatUser)
  func senderDidRead(user: PrivateChatUser)
  func messageShouldCountAsUnread(message: Indexed<Message>, for user: PrivateChatUser) -> Bool
  func unreadMessages(count: Int, message: Indexed<Message>?)
}
