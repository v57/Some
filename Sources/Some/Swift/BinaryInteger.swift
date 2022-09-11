//
//  File.swift
//  
//
//  Created by Dmitry Kozlov on 4/29/20.
//

import Foundation

public enum BytesStringFormat {
  case pretty, short
}
public extension BinaryInteger {
  var digits: Int {
    return self == 0 ? 1 : Int(log10(Double(magnitude))) * Int(signum()) + 1
  }
  func multiply(by: Double) -> Self {
    Self(Double(self) * by)
  }
  var double: Double { Double(self) }
  func binary() -> String {
    String(self, radix: 2)
  }
  func binary(_ padding: Int) -> String {
    let string = String(self, radix: 2)
    return String(repeating: "0", count: max(padding - string.count,0)) + string
  }
  func bytesString(_ format: BytesStringFormat = .pretty) -> String {
    switch format {
    case .pretty:
      switch self {
      case 0...1024:
        return "\(self) B"
      case 0...1024*1024:
        return "\(Double(self).devide(by: 1024).precision(1)) KB"
      case 0...1024*1024*1024:
        return "\(Double(self).devide(by: 1024*1024).precision(1)) MB"
      case 0...1024*1024*1024*1024:
        return "\(Double(self).devide(by: 1024*1024*1024).precision(1)) GB"
      default:
        return "\(Double(self).devide(by: 1024*1024*1024*1024).precision(1)) TB"
      }
    case .short:
      switch self {
      case 0...1024:
        return "\(self)b"
      case 0...1024*1024:
        return "\(Double(self).devide(by: 1024).precision(1))kb"
      case 0...1024*1024*1024:
        return "\(Double(self).devide(by: 1024*1024).precision(1))mb"
      case 0...1024*1024*1024*1024:
        return "\(Double(self).devide(by: 1024*1024*1024).precision(1))gb"
      default:
        return "\(Double(self).devide(by: 1024*1024*1024*1024).precision(1))tb"
      }
    }
  }
  var kb: Self { self * 1024 }
  var mb: Self { self * 1024 * 1024 }
  var gb: Self { self * 1024 * 1024 * 1024 }
  var toKB: Self { self / 1024 }
  var toMB: Self { self / 1048576 }
}

/// Number to string convertion options
public struct NumberToStringOptions: OptionSet {
  public let rawValue: Int
  public init(rawValue: Int) {
    self.rawValue = rawValue
  }
  /// Fallback to scientific number. (like `1.0e-16`)
  public static let fallbackToScientific = NumberToStringOptions(rawValue: 0b1)
  /// Removes last zeroes (will print `1.123` instead of `1.12300000000000`)
  public static let stripZeroes = NumberToStringOptions(rawValue: 0b10)
  /// Default options: [.stripZeroes]
  public static let `default`: NumberToStringOptions = [.stripZeroes]
}

public extension FixedWidthInteger {
  /// - Parameter string: String number. can be: "0.023", "123123123.12312312312"
  /// - Parameter decimals: Number of decimals that string should be multiplyed by
  init?(_ string: String, decimals: Int) {
    let separators = CharacterSet(charactersIn: ".,")
    let components = string.trimmingCharacters(in: .whitespacesAndNewlines).components(separatedBy: separators)
    guard components.count == 1 || components.count == 2 else { return nil }
    let unitDecimals = decimals
    guard var mainPart = Self.init(components[0], radix: 10) else { return nil }
    mainPart *= Self(10).power(unitDecimals)
    if components.count == 2 {
      let numDigits = components[1].count
      guard numDigits <= unitDecimals else { return nil }
      guard let afterDecPoint = Self.init(components[1], radix: 10) else { return nil }
      let extraPart = afterDecPoint * Self(10).power(unitDecimals - numDigits)
      mainPart += extraPart
    }
    self = mainPart
  }
  mutating func increment() -> Self {
    self &+= 1
    return self
  }
}

// MARK: - To String with radix
public extension BinaryInteger {
  func power(_ exponent: Int) -> Self {
    if exponent == 0 { return 1 }
    if exponent == 1 { return self }
    if exponent < 0 {
      precondition(self != 0)
      return self == 1 ? 1 : 0
    }
    let signum = self.signum()
    var b = self * signum
    if b <= 1 { return self }
    var result = Self(1)
    var e = exponent
    while e > 0 {
      if e & 1 == 1 {
        result *= b
      }
      e >>= 1
      b *= b
    }
    if signum == -1 && exponent & 1 != 0 {
      return result * -1
    } else {
      return result
    }
  }
  /// Formats Number to String. The supplied number is first divided into integer and decimal part based on "toUnits",
  /// then limit the decimal part to "decimals" symbols and uses a "decimalSeparator" as a separator.
  /// Fallbacks to scientific format if higher precision is required.
  /// default: decimals: 18, decimalSeparator: ".", options: .stripZeroes
  func string(unitDecimals: Int, decimals: Int, decimalSeparator: String = ".", options: NumberToStringOptions = .default) -> String {
    guard self != 0 else { return "0" }
    var toDecimals = decimals
    if unitDecimals < toDecimals {
      toDecimals = unitDecimals
    }
    
    let divisor = Self(10).power(unitDecimals)
    let (quotient, remainder) = (self * signum()).quotientAndRemainder(dividingBy: divisor)
    var fullRemainder = String(remainder)
    let fullPaddedRemainder = fullRemainder.leftPadding(toLength: unitDecimals, withPad: "0")
    let remainderPadded = fullPaddedRemainder[0 ..< toDecimals]
    let offset = remainderPadded.reversed().firstIndex(where: { $0 != "0" })?.base
    
    if let offset = offset {
      if toDecimals == 0 {
        return sign + String(quotient)
      } else if options.contains(.stripZeroes) {
        return sign + String(quotient) + decimalSeparator + remainderPadded[..<offset]
      } else {
        return sign + String(quotient) + decimalSeparator + remainderPadded
      }
    } else if quotient != 0 || !options.contains(.fallbackToScientific) {
      return sign + String(quotient)
    } else {
      var firstDigit = 0
      for char in fullPaddedRemainder {
        if char == "0" {
          firstDigit = firstDigit + 1
        } else {
          let firstDecimalUnit = String(fullPaddedRemainder[firstDigit ..< firstDigit+1])
          var remainingDigits = ""
          let numOfRemainingDecimals = fullPaddedRemainder.count - firstDigit - 1
          if numOfRemainingDecimals <= 0 {
            remainingDigits = ""
          } else if numOfRemainingDecimals > decimals {
            let end = firstDigit+1+decimals > fullPaddedRemainder.count ? fullPaddedRemainder.count : firstDigit+1+decimals
            remainingDigits = String(fullPaddedRemainder[firstDigit+1 ..< end])
          } else {
            remainingDigits = String(fullPaddedRemainder[firstDigit+1 ..< fullPaddedRemainder.count])
          }
          fullRemainder = firstDecimalUnit
          if !remainingDigits.isEmpty {
            fullRemainder += decimalSeparator + remainingDigits
          }
          firstDigit = firstDigit + 1
          break
        }
      }
      return sign + fullRemainder + "e-" + String(firstDigit)
    }
  }
  
  private var sign: String {
    return signum() == -1 ? "-" : ""
  }
}
private func _charsPerWord(forRadix radix: Int) -> (chars: Int, power: UInt) {
  var power: UInt = 1
  var overflow = false
  var count = 0
  while !overflow {
    let (p, o) = power.multipliedReportingOverflow(by: UInt(radix))
    overflow = o
    if !o || p == 0 {
      count += 1
      power = p
    }
  }
  return (count, power)
}

private extension String {
  func leftPadding(toLength: Int, withPad character: Character) -> String {
    let stringLength = count
    if stringLength < toLength {
      return String(repeatElement(character, count: toLength - stringLength)) + self
    } else {
      return String(suffix(toLength))
    }
  }
  subscript(index: Int) -> String {
    get {
      return String(self[self.index(index)])
    } set {
      let index = self.index(index)
      replaceSubrange(index..<self.index(after: index), with: newValue)
    }
  }
  
  subscript(bounds: CountableClosedRange<Int>) -> String {
    let start = index(bounds.lowerBound)
    let end = index(bounds.upperBound)
    return String(self[start...end])
  }
  
  subscript(bounds: CountableRange<Int>) -> String {
    let start = index(startIndex, offsetBy: bounds.lowerBound)
    let end = index(startIndex, offsetBy: bounds.upperBound)
    return String(self[start ..< end])
  }
  
  subscript(bounds: CountablePartialRangeFrom<Int>) -> String {
    let start = index(startIndex, offsetBy: bounds.lowerBound)
    let end = endIndex
    return String(self[start ..< end])
  }
  subscript(range: PartialRangeUpTo<Int>) -> Substring {
    return self[..<index(range.upperBound)]
  }
  @inline(__always)
  func index(_ i: Int) -> String.Index {
    return index(startIndex, offsetBy: i)
  }
}
