//
//  Numbers.swift
//  Some
//
//  Created by Димасик on 12/13/17.
//  Copyright © 2017 Dmitry Kozlov. All rights reserved.
//

import Foundation

enum Types: UInt8 {
  case u64 = 200, u32, u16, u8
}

public protocol FixedWidth: DataRepresentable {
  init()
}
extension UInt8: FixedWidth {}
extension UInt16: FixedWidth {}
extension UInt32: FixedWidth {}
extension UInt64: FixedWidth {}
extension UInt: FixedWidth {}
extension Int8: FixedWidth {}
extension Int16: FixedWidth {}
extension Int32: FixedWidth {}
extension Int64: FixedWidth {}
extension Int: FixedWidth {}
extension Float: FixedWidth {}
extension Double: FixedWidth {}
extension Bool: FixedWidth {}

// extension Array: DataRepresentable where Element: DataRepresentable {
//   public init(data: DataReader) throws {
//     if data.compress {
//       let count: Int = try data.intCount()
//       self.init()
//       reserveCapacity(count)
//       for _ in 0..<count {
//         let element: Element = try data.next()
//         append(element)
//       }
//     } else {
//       let size = MemoryLayout<Element>.stride
//       let count: Int = try data.intCount()
//       self = try data.subdata(count*size).withUnsafeBytes {
//         Array($0.bindMemory(to: Element.self))
//       }
//     }
//   }
//   public func save(data: DataWriter) {
//     data.append(count)
//     if data.compress {
//       forEach {
//         data.append($0)
//       }
//     } else {
//       var a = self
//       data.data.append(UnsafeBufferPointer(start: &a, count: count))
//     }
//   }
// }
//
// extension Set: DataRepresentable where Element: DataRepresentable {
//   public init(data: DataReader) throws {
//     let count: Int = try data.intCount()
//     self = Set<Element>()
//     reserveCapacity(count)
//     for _ in 0..<count {
//       let value: Element = try data.next()
//       insert(value)
//     }
//   }
//
//   public func save(data: DataWriter) {
//     data.append(count)
//     forEach {
//       data.append($0)
//     }
//   }
// }
//
extension Range: DataRepresentable where Element: DataRepresentable {
  public init(data: DataReader) throws {
    self = try data.next()..<data.next()
  }
  public func save(data: DataWriter) {
    data.append(lowerBound)
    data.append(upperBound)
  }
}
extension ClosedRange: DataRepresentable where Element: DataRepresentable {
  public init(data: DataReader) throws {
    self = try data.next()...data.next()
  }
  public func save(data: DataWriter) {
    data.append(lowerBound)
    data.append(upperBound)
  }
}
//
// extension ArraySlice: PrimitiveDecodable where Element: PrimitiveDecodable {
//   public func save(data: DataWriter) {
//     data.append(count)
//     forEach {
//       $0.save(data: data)
//     }
//   }
// }

//#if __LP64__
extension UInt: DataRepresentable {
  public init(data: DataReader) throws {
    let raw: UInt8 = try data.next()
    if let type = Types(rawValue: raw) {
      switch type {
      case .u8:
        let value: UInt8 = try data.convert()
        self.init(value)
      case .u16:
        let value: UInt16 = try data.convert()
        self.init(value)
      case .u32:
        let value: UInt32 = try data.convert()
        self.init(value)
      case .u64:
        let value: UInt64 = try data.convert()
        self.init(value)
      }
    } else if raw < 100 {
      self.init(raw)
    } else {
      throw corrupted
    }
  }
  public func save(data: DataWriter) {
    if self < 100 {
      data.data.append(UInt8(self))
    } else if self <= 0xff {
      data.data.append(Types.u8)
      data.data.append(UInt8(self))
    } else if self <= 0xffff {
      data.data.append(Types.u16)
      data.data.append(UInt16(self))
    } else if self <= 0xffffffff {
      data.data.append(Types.u32)
      data.data.append(UInt32(self))
    } else {
      data.data.append(Types.u64)
      data.data.append(UInt64(self))
    }
  }
}
extension Int: DataRepresentable {
  public init(data: DataReader) throws {
    let raw: UInt8 = try data.next()
    if let type = Types(rawValue: raw) {
      switch type {
      case .u8:
        let value: Int8 = try data.convert()
        self.init(value)
      case .u16:
        let value: Int16 = try data.convert()
        self.init(value)
      case .u32:
        let value: Int32 = try data.convert()
        self.init(value)
      case .u64:
        let value: Int64 = try data.convert()
        self.init(value)
      }
    } else if raw < 100 {
      self.init(raw)
    } else if raw < 200 {
      self.init(Int(raw)-200)
    } else {
      throw corrupted
    }
  }
  public func save(data: DataWriter) {
    if self >= 0 && self < 100 {
      data.data.append(UInt8(self))
    } else if self >= -100 && self < 0 {
      data.data.append(UInt8(self+200))
    } else if self <= 0x7f && self >= -0x7f {
      data.data.append(Types.u8)
      data.data.append(Int8(self))
    } else if self <= 0x7fff && self >= -0x7fff {
      data.data.append(Types.u16)
      data.data.append(Int16(self))
    } else if self <= 0x7fffffff && self >= -0x7fffffff {
      data.data.append(Types.u32)
      data.data.append(Int32(self))
    } else {
      data.data.append(Types.u64)
      data.data.append(Int64(self))
    }
  }
}
//#else
//
//extension UInt: DataRepresentable {
//  public init(data: DataReader) throws {
//    let raw: UInt8 = try data.next()
//    if let type = Types(rawValue: raw) {
//      switch type {
//      case .u8:
//        let value: UInt8 = try data.convert()
//        self.init(value)
//      case .u16:
//        let value: UInt16 = try data.convert()
//        self.init(value)
//      case .u32:
//        let value: UInt32 = try data.convert()
//        self.init(value)
//      default:
//        throw corrupted
//      }
//    } else if raw < 100 {
//      self.init(raw)
//    } else {
//      throw corrupted
//    }
//  }
//  public func save(data: DataWriter) {
//    if self < 100 {
//      data.data.append(UInt8(self))
//    } else if self <= 0xff {
//      data.data.append(Types.u8)
//      data.data.append(UInt8(self))
//    } else if self <= 0xffff {
//      data.data.append(Types.u16)
//      data.data.append(UInt16(self))
//    } else {
//      data.data.append(Types.u32)
//      data.data.append(UInt32(self))
//    }
//  }
//}
//extension Int: DataRepresentable {
//  public init(data: DataReader) throws {
//    let raw: UInt8 = try data.next()
//    if let type = Types(rawValue: raw) {
//      switch type {
//      case .u8:
//        let value: Int8 = try data.convert()
//        self.init(value)
//      case .u16:
//        let value: Int16 = try data.convert()
//        self.init(value)
//      case .u32:
//        let value: Int32 = try data.convert()
//        self.init(value)
//      default:
//        throw corrupted
//      }
//    } else if raw < 100 {
//      self.init(raw)
//    } else if raw < 200 {
//      self.init(Int(raw)-200)
//    } else {
//      throw corrupted
//    }
//  }
//  public func save(data: DataWriter) {
//    if self >= 0 && self < 100 {
//      data.data.append(UInt8(self))
//    } else if self >= -100 && self < 0 {
//      data.data.append(UInt8(self+200))
//    } else if self <= 0x7f && self >= -0x7f {
//      data.data.append(Types.u8)
//      data.data.append(Int8(self))
//    } else if self <= 0x7fff && self >= -0x7fff {
//      data.data.append(Types.u16)
//      data.data.append(Int16(self))
//    } else {
//      data.data.append(Types.u32)
//      data.data.append(Int32(self))
//    }
//  }
//}
//#endif
extension UInt64: DataRepresentable {
  public init(data: DataReader) throws {
    let raw: UInt8 = try data.next()
    if let type = Types(rawValue: raw) {
      switch type {
      case .u8:
        let value: UInt8 = try data.convert()
        self.init(value)
      case .u16:
        let value: UInt16 = try data.convert()
        self.init(value)
      case .u32:
        let value: UInt32 = try data.convert()
        self.init(value)
      case .u64:
        let value: UInt64 = try data.convert()
        self.init(value)
      }
    } else if raw < 100 {
      self.init(raw)
    } else {
      throw corrupted
    }
  }
  public func save(data: DataWriter) {
    let max: UInt64 = 0xffffffff
    if self < 100 {
      data.data.append(UInt8(self))
    } else if self <= 0xff {
      data.data.append(Types.u8)
      data.data.append(UInt8(self))
    } else if self <= 0xffff {
      data.data.append(Types.u16)
      data.data.append(UInt16(self))
    } else if self <= max {
      data.data.append(Types.u32)
      data.data.append(UInt32(self))
    } else {
      data.data.append(Types.u64)
      data.data.append(self)
    }
  }
}
extension UInt32: DataRepresentable {
  public init(data: DataReader) throws {
    let raw: UInt8 = try data.next()
    if let type = Types(rawValue: raw) {
      switch type {
      case .u8:
        let value: UInt8 = try data.convert()
        self.init(value)
      case .u16:
        let value: UInt16 = try data.convert()
        self.init(value)
      case .u32:
        let value: UInt32 = try data.convert()
        self.init(value)
      default:
        throw corrupted
      }
    } else if raw < 100 {
      self.init(raw)
    } else {
      throw corrupted
    }
  }
  public func save(data: DataWriter) {
    if self < 100 {
      data.data.append(UInt8(self))
    } else if self <= 0xff {
      data.data.append(Types.u8)
      data.data.append(UInt8(self))
    } else if self <= 0xffff {
      data.data.append(Types.u16)
      data.data.append(UInt16(self))
    } else {
      data.data.append(Types.u32)
      data.data.append(self)
    }
  }
}
extension UInt16: DataRepresentable {
  public init(data: DataReader) throws {
    self = try data.convert()
  }
  
  public func save(data: DataWriter) {
    data.data.append(self)
  }
}
extension UInt8: DataRepresentable {
  public init(data: DataReader) throws {
    self = try data.convert()
  }
  
  public func save(data: DataWriter) {
    data.data.append(self)
  }
}

extension Int64: DataRepresentable {
  public init(data: DataReader) throws {
    let raw: UInt8 = try data.next()
    if let type = Types(rawValue: raw) {
      switch type {
      case .u8:
        let value: Int8 = try data.convert()
        self.init(value)
      case .u16:
        let value: Int16 = try data.convert()
        self.init(value)
      case .u32:
        let value: Int32 = try data.convert()
        self.init(value)
      case .u64:
        let value: Int64 = try data.convert()
        self.init(value)
      }
    } else if raw < 100 {
      self.init(raw)
    } else if raw < 200 {
      self.init(Int64(raw)-200)
    } else {
      throw corrupted
    }
  }
  public func save(data: DataWriter) {
    if self >= 0 && self < 100 {
      data.data.append(UInt8(self))
    } else if self >= -100 && self < 0 && self < 0 {
      data.data.append(UInt8(self+200))
    } else if self <= 0x7f && self >= -0x7f {
      data.data.append(Types.u8)
      data.data.append(Int8(self))
    } else if self <= 0x7fff && self >= -0x7fff {
      data.data.append(Types.u16)
      data.data.append(Int16(self))
    } else if self <= 0x7fffffff && self >= -0x7fffffff {
      data.data.append(Types.u32)
      data.data.append(Int32(self))
    } else {
      data.data.append(Types.u64)
      data.data.append(Int64(self))
    }
  }
}
extension Int32: DataRepresentable {
  public init(data: DataReader) throws {
    let raw: UInt8 = try data.next()
    if let type = Types(rawValue: raw) {
      switch type {
      case .u8:
        let value: Int8 = try data.convert()
        self.init(value)
      case .u16:
        let value: Int16 = try data.convert()
        self.init(value)
      case .u32:
        let value: Int32 = try data.convert()
        self.init(value)
      default: throw corrupted
      }
    } else if raw < 100 {
      self.init(raw)
    } else if raw < 200 {
      self.init(Int32(raw)-200)
    } else {
      throw corrupted
    }
  }
  public func save(data: DataWriter) {
    if self >= 0 && self < 100 {
      data.data.append(UInt8(self))
    } else if self >= -100 && self < 0 {
      data.data.append(UInt8(self+200))
    } else if self <= 0x7f && self >= -0x7f {
      data.data.append(Types.u8)
      data.data.append(Int8(self))
    } else if self <= 0x7fff && self >= -0x7fff {
      data.data.append(Types.u16)
      data.data.append(Int16(self))
    } else {
      data.data.append(Types.u32)
      data.data.append(Int32(self))
    }
  }
}
extension Int16: DataRepresentable {
  public init(data: DataReader) throws {
    self = try data.convert()
  }
  public func save(data: DataWriter) {
    data.data.append(self)
  }
}
extension Int8: DataRepresentable {
  public init(data: DataReader) throws {
    self = try data.convert()
  }
  public func save(data: DataWriter) {
    data.data.append(self)
  }
}

extension Float: DataRepresentable {
  public init(data: DataReader) throws {
    self = try data.convert()
  }
  public func save(data: DataWriter) {
    data.data.append(self)
  }
}
extension Double: DataRepresentable {
  public init(data: DataReader) throws {
    self = try data.convert()
  }
  public func save(data: DataWriter) {
    data.data.append(self)
  }
}
extension Bool: DataRepresentable {
  public init(data: DataReader) throws {
    let value = try data.uint8()
    switch value {
    case 0: self = false
    case 1: self = true
    default: throw corrupted
    }
  }
  public func save(data: DataWriter) {
    data.data.append(self)
  }
}
