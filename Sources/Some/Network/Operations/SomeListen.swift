//
//  Listen.swift
//  Network
//
//  Created by Димасик on 9/20/17.
//  Copyright © 2017 Dmitry Kozlov. All rights reserved.
//

import Foundation

extension StreamOperations {
  @discardableResult
  public func listen() -> Self {
    let operation = SomeListenOperation()
    add(operation)
    return self
  }
}

private class SomeListenOperation: StreamOperation {
  override var cname: String { return "listen()" }
  override init() {
    super.init()
  }
  override func run() {
    let stream = self.stream as! SomeStream2
    stream.listen()
    
    Stream.debugSleep()
    completion(status: .success, action: .next)
  }
}
