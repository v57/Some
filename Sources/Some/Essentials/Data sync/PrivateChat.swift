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
public extension ASPrivateChat {
  var sender: PrivateChatUser {
    get { users[value: senderId] }
    set { users[value: senderId] = newValue }
  }
  var recipient: PrivateChatUser {
    get { users.opposite(of: senderId) }
    set { users.editOpposite(of: senderId, edit: { $0 = newValue }) }
  }
  func updated(users: Vector2<PrivateChatUser>) {
    var oldValue = self.users
    var users = users
    let sender = self.sender
    self.users = users
    
    // converting users.a to sender and users.b to recipient
    if sender == users.b {
      oldValue.swap()
      users.swap()
    }
    
    if oldValue.a.lastRead != users.a.lastRead {
      senderDidRead(user: users.a)
      let unread = countUnreadMessages(for: users.a)
      unreadMessages(count: unread.count, message: unread.message)
    }
    if oldValue.b.lastRead != users.b.lastRead {
      recipientDidRead(user: users.b)
    }
  }
  func read(at index: Int) {
    let index = min(header.itemsCount, index)
    guard index > sender.lastRead else { return }
  }
  func countUnreadMessages(for user: PrivateChatUser) -> (count: Int, message: Indexed<Message>?) {
    var count = header.itemsCount - user.lastRead
    guard count > 0 else { return (count, nil) }
    guard let part = items.body.last else { return (count, nil) }
    var lastMessage: Indexed<Message>?
    part.enumerate(from: max(0, sender.lastRead - part.index)) { i, message, stop in
      if !messageShouldCountAsUnread(message: message, for: user) {
        count -= 1
        lastMessage = message
      }
    }
    return (count, lastMessage)
  }
}
