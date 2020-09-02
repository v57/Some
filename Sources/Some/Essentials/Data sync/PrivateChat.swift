//
//  File.swift
//  
//
//  Created by Dmitry Kozlov on 9/2/20.
//

import Foundation

public protocol ASChatUser: ComparsionValue where ValueToCompare == Int {
  var id: Int { get }
  var lastRead: Int { get set }
}
public extension ASChatUser {
  var _valueToCompare: Int { id }
}
public protocol ASPrivateChat: ArraySyncChat {
  associatedtype ChatUser: ASChatUser
  var users: Vector2<ChatUser> { get set }
  func recipientDidRead(user: ChatUser)
  func senderDidRead(user: ChatUser)
  func messageShouldCountAsUnread(message: Indexed<Message>, for user: ChatUser) -> Bool
  func unreadMessages(count: Int, message: Indexed<Message>?)
}
public extension ASPrivateChat {
  var sender: ChatUser {
    get { users[value: senderId] }
    set { users[value: senderId] = newValue }
  }
  var recipient: ChatUser {
    get { users.opposite(of: senderId) }
    set { users.editOpposite(of: senderId, edit: { $0 = newValue }) }
  }
  func updated(user: ChatUser, oldValue: ChatUser) {
    guard oldValue.lastRead != user.lastRead else { return }
    if user.id == senderId {
      senderDidRead(user: user)
      let unread = countUnreadMessages(for: user)
      unreadMessages(count: unread.count, message: unread.message)
    } else {
      recipientDidRead(user: user)
    }
  }
  func updated(users: Vector2<ChatUser>) {
    let oldValue = self.users
    self.users = users
    updated(user: users.a, oldValue: oldValue.a)
    updated(user: users.b, oldValue: oldValue.b)
  }
  func read(at index: Int) {
    let index = min(header.itemsCount, index)
    guard index > sender.lastRead else { return }
  }
  func countUnreadMessages(for user: ChatUser) -> (count: Int, message: Indexed<Message>?) {
    var count = header.itemsCount - user.lastRead
    guard count > 0 else { return (count, nil) }
    guard let part = items.body.last else { return (count, nil) }
    var lastMessage: Indexed<Message>?
    part.enumerate(from: max(0, user.lastRead - part.index)) { i, message, stop in
      if !messageShouldCountAsUnread(message: message, for: user) {
        count -= 1
        lastMessage = message
      }
    }
    return (count, lastMessage)
  }
}
