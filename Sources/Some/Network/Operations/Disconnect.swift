//
//  Disconnect.swift
//  Network
//
//  Created by Димасик on 9/20/17.
//  Copyright © 2017 Dmitry Kozlov. All rights reserved.
//

import Foundation

extension StreamOperations {
  @discardableResult
  public func disconnect() -> Self {
    let operation = DisconnectOperation()
    add(operation)
    return self
  }
}

private class DisconnectOperation: StreamOperation {
  override var cname: String { return "disconnect()" }
  override init() {
    super.init()
  }
  override func run() {
    stream.disconnect()
    Stream.debugSleep()
    self.completion(status: .success, action: .next)
  }
  enum Response {
    case success, lostConnection
  }
}
