//
//  SendStreamOperation.swift
//  Network
//
//  Created by Димасик on 9/20/17.
//  Copyright © 2017 Dmitry Kozlov. All rights reserved.
//

import Foundation

extension StreamOperations {
  @discardableResult
  public func sendStream(stream: @escaping ()->(Data?)) -> Self {
    let operation = SendStreamOperation(stream: stream)
    add(operation)
    return self
  }
}

private class SendStreamOperation: StreamOperation {
  override var cname: String { return "send(stream:)" }
  let onStream: ()->(Data?)
  init(stream: @escaping ()->(Data?)) {
    self.onStream = stream
    super.init()
  }
  override func run() {
    stream.send(stream: onStream) { response in
      Stream.debugSleep()
      switch response {
      case .success:
        self.completion(status: .success, action: .next)
      case .lostConnection:
        self.completion(status: .lostConnection, action: .restart)
      }
    }
  }
}
