//
//  ReadOperation.swift
//  Network
//
//  Created by Димасик on 9/20/17.
//  Copyright © 2017 Dmitry Kozlov. All rights reserved.
//

import Foundation

extension StreamOperations {
  @discardableResult
  func _read(completion: @escaping (Data)throws->()) -> Self {
    let operation = ReadOperation(completion: completion)
    add(operation)
    return self
  }
}

private class ReadOperation: StreamOperation {
  override var cname: String { return "read()" }
  let onCompletion: (Data)throws->()
  init(completion: @escaping (Data)throws->()) {
    self.onCompletion = completion
    super.init()
  }
  override func run() {
    stream.read { response in
      Stream.debugSleep()
      switch response {
      case .success(let data):
        do {
          try self.onCompletion(data)
          self.completion(status: .success, action: .next)
        } catch {
          self.completion(status: .failed(error: error), action: .stop)
        }
      case .lostConnection:
        self.completion(status: .lostConnection, action: .restart)
      }
    }
  }
}

