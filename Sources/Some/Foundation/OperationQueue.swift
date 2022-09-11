//
//  File.swift
//  
//
//  Created by Dmitry Kozlov on 24.11.2021.
//

import Foundation

public extension OperationQueue {
  static let background = OperationQueue(0, .background)
  static let singlePerformant = OperationQueue(1)
  static var images: OperationQueue = {
    let queue = OperationQueue()
    queue.maxConcurrentOperationCount = 1
    return queue
  }()
  convenience init(_ threads: Int, _ qualityOfService: QualityOfService = .default) {
    self.init()
    maxConcurrentOperationCount = threads
    self.qualityOfService = qualityOfService
  }
  func run<T>(_ operation: @escaping () -> T) async -> T {
    await withUnsafeContinuation { task in
      addOperation {
        task.resume(returning: operation())
      }
    }
  }
  func tryRun<T>(_ operation: @escaping () throws -> T) async throws -> T {
    try await withUnsafeThrowingContinuation { task in
      addOperation {
        do {
          let value = try operation()
          task.resume(returning: value)
        } catch {
          task.resume(throwing: error)
        }
      }
    }
  }
}
