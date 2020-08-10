//
//  H.swift
//  
//
//  Created by Dmitry Kozlov on 5/4/20.
//

// open class H<T>: P<T> {
//   public var history: [T]
//   
//   public override init() {
//     history = []
//     super.init()
//   }
//   public init(_ values: T...) {
//     history = values
//     super.init()
//   }
//   public init(_ values: T?...) {
//     history = values.compactMap { $0 }
//     super.init()
//   }
//   
//   open override func connect(_ connection: Connection<T>) {
//     guard !history.contains(where: { !connection.send($0) }) else { return }
//     super.connect(connection)
//   }
//   open override func send(_ value: T) {
//     history.append(value)
//     super.send(value)
//   }
//   public func osend(_ value: T?) {
//     guard let value = value else { return }
//     self.send(value)
//   }
// }
