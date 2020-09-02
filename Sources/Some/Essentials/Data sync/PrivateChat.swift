//
//  File.swift
//  
//
//  Created by Dmitry Kozlov on 9/2/20.
//

import Foundation

public protocol ArraySyncPrivateChat: ReadableChat {
  var users: Vector2<ChatUser> { get set }
  func recipientDidRead(user: ChatUser)
  func senderDidRead(user: ChatUser)
}
public extension ArraySyncPrivateChat {
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
}
