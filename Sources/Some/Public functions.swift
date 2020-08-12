
//  The MIT License (MIT)
//
//  Copyright (c) 2016 Dmitry Kozlov
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in all
//  copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
//  SOFTWARE.

import Foundation

public enum SomeSettings {
  
}

/// returns class name in string format
/**
 let a = 10
 let b = className(a) // b = "Int"
 let c = className(b) // c = "String"
 */
public func className(_ item: Any) -> String {
  String(describing: item is Any.Type ? item : type(of: item))
}

public func increment2d(_ x: inout Int, _ y: inout Int, _ width: Int) {
  x += 1
  if x >= width {
    x = 0
    y += 1
  }
}

public func ename(_ error: Error?) -> String {
  if let error = error {
    return String(describing: error)
  } else {
    return "nil"
  }
}

public func recursive<T>(_ object: T, _ path: KeyPath<T, T?>) -> [T] {
  var array = [T]()
  var object = object
  while let value = object[keyPath: path] {
    object = value
    array.append(value)
  }
  return array
}

public func onCatch(_ description: String, code: ()throws->()) {
  do {
    try code()
  } catch {
    print("\(description): \(error)")
  }
}

public func temp<T>(_ value: inout T, _ new: T, _ action: ()throws->()) rethrows {
  let v = value
  value = new
  defer { value = v }
  try action()
}

@discardableResult
public func mapError<T>(_ execute: @autoclosure () throws -> (T), _ mappedError: Error) throws -> T {
  do {
    return try execute()
  } catch {
    throw mappedError
  }
}
