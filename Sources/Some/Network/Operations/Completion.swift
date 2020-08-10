//
//  CompletionOperation.swift
//  Network
//
//  Created by Димасик on 9/20/17.
//  Copyright © 2017 Dmitry Kozlov. All rights reserved.
//

import Foundation


extension StreamOperations {
  @discardableResult
  public func success(_ completion: @escaping ()->()) -> Self {
    let operation = CompletionOperation(completion: completion)
    add(operation)
    return self
  }
  @discardableResult
  public func syncSuccess(_ completion: @escaping ()->()) -> Self {
    let operation = SyncCompletionOperation(completion: completion)
    add(operation)
    return self
  }
}

private class CompletionOperation: StreamOperation {
  override var cname: String { return "success()" }
  let completion: ()->()
  init(completion: @escaping ()->()) {
    self.completion = completion
    super.init()
  }
  override func run() {
    Stream.debugSleep()
    DispatchQueue.main.async {
      self.completion()
      self.completion(status: .success, action: .next)
    }
  }
}

private class SyncCompletionOperation: StreamOperation {
  override var cname: String { return "success()" }
  let completion: ()->()
  init(completion: @escaping ()->()) {
    self.completion = completion
    super.init()
  }
  override func run() {
    Stream.debugSleep()
    self.completion()
    self.completion(status: .success, action: .next)
  }
}
