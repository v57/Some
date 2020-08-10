//
//  SendOperation.swift
//  Network
//
//  Created by Димасик on 9/20/17.
//  Copyright © 2017 Dmitry Kozlov. All rights reserved.
//

import Foundation

extension StreamOperations {
  @discardableResult
  public func send(data: Data) -> Self {
    let operation = SendOperation(data: data)
    add(operation)
    return self
  }
}

class SendOperation: StreamOperation {
  override var cname: String { return "send()" }
  let data: Data
  init(data: Data) {
    self.data = data
    super.init()
  }
  override func run() {
    stream.send(data: data) { response in
      Stream.debugSleep()
      switch response {
      case .success:
        self.completion(status: .success, action: .next)
      case .lostConnection:
        self.completion(status: .lostConnection, action: .restart)
      }
    }
  }
  enum Response {
    case success, lostConnection
  }
}
