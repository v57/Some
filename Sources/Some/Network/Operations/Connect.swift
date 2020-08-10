//
//  ConnectOperation.swift
//  Network
//
//  Created by Димасик on 9/20/17.
//  Copyright © 2017 Dmitry Kozlov. All rights reserved.
//

import Foundation

extension StreamOperations {
  @discardableResult
  public func connect() -> Self {
    let operation = ConnectOperation()
    add(operation)
    return self
  }
}

private class ConnectOperation: StreamOperation {
  override var cname: String { return "connect()" }
  override init() {
    super.init()
  }
  override func run() {
    stream.connect { success in
      Stream.debugSleep()
      if success {
        self.completion(status: .success, action: .next)
      } else {
        self.completion(status: .lostConnection, action: .restart)
      }
    }
  }
  enum Response {
    case success, lostConnection
  }
}
