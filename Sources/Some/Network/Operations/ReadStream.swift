//
//  ReadStreamOperation.swift
//  Network
//
//  Created by Димасик on 9/20/17.
//  Copyright © 2017 Dmitry Kozlov. All rights reserved.
//

import Foundation

extension StreamOperations {
  @discardableResult
  public func readStream(stream: @escaping (Data)->(Bool)) -> Self {
    let operation = ReadStreamOperation(stream: stream)
    add(operation)
    return self
  }
}

class ReadStreamOperation: StreamOperation {
  override var cname: String { return "read(stream:)" }
  let onStream: (Data)->(Bool)
  init(stream: @escaping (Data)->(Bool)) {
    onStream = stream
    super.init()
  }
  override func run() {
    stream.read(id: .random(), stream: onStream) { response in
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
