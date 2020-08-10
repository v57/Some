//
//  FutureRepeater.swift
//  SomeNetwork
//
//  Created by Dmitry on 12/07/2019.
//  Copyright © 2019 Дмитрий Козлов. All rights reserved.
//

import Foundation

public class FutureRepeater<T>: Future<T> {
  public enum State {
    case idle, running, cancelling
  }
  
  public var makeFuture: ()->(Future<T>)
  public var attempt = 0
  public var state = State.idle
  public var delay = 5.0
  
  private var _repeatTime: ((FutureRepeater<T>) -> (Double))?
  private var _processError = [(Error, FutureRepeater<T>) throws -> ()]()
  private var _attemptHandlers = [(Int)->()]()
  
  public init(_ makeFuture: @escaping ()->(Future<T>)) {
    self.makeFuture = makeFuture
    super.init()
  }
  @discardableResult
  public func processError(_ processError: @escaping (Error, FutureRepeater<T>) throws -> ()) -> Self {
    self._processError.append(processError)
    return self
  }
  @discardableResult
  public func start() -> Self {
    if state == .cancelling {
      state = .running
    }
    guard state != .running else { return self }
    attempt += 1
    state = .running
    makeFuture().pipe { self._completed($0) }
    return self
  }
  private func _completed(_ result: FutureResult<T>) {
    switch result {
    case .success(let value):
      self.success(value)
    case .failure(let error):
      if state == .cancelling {
        state = .idle
      } else {
        state = .idle
        do {
          try _processError.forEach { try $0(error, self) }
          DispatchQueue.main.wait(delay) {
            _ = self.start()
          }
        } catch {
          fail(error)
        }
      }
    }
  }
  private func _repeat() {
    
  }
  public func cancel() {
    if state == .running {
      state = .cancelling
    }
  }
}
