//
//  File.swift
//  
//
//  Created by Dmitry Kozlov on 9/2/20.
//

import Foundation

public protocol ReadableChat: ArraySyncChat {
  associatedtype ChatUser: ArraySyncChatUser
  var sender: ChatUser { get }
  func messageShouldCountAsUnread(message: Indexed<Message>, for user: ChatUser) -> Bool
  func updated(user: ChatUser, oldValue: ChatUser)
  func unreadMessages(count: Int, message: Indexed<Message>?)
}
public extension ReadableChat {
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
