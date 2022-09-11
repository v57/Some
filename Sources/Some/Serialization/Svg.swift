//
//  File.swift
//
//
//  Created by Dmitry Kozlov on 09.07.2021.
//

#if canImport(Compression)
import Foundation

public extension String {
  var codeSvg: Svg { try! DataReader(data: replacingOccurrences(of: "\n", with: "").base64().decompress(.zlib)!).next() }
}

// MARK: - Svg
public struct Svg {
  public enum ParsingError: Error {
    case corrupted
  }
  public struct Transform {
    public var a, b, c, d, tx, ty: Float
  }
  public struct Point {
    public var x: Float
    public var y: Float
    public init(x: Float, y: Float) {
      self.x = x
      self.y = y
    }
  }
  public enum Element {
    case move(Point)
    case line(Point)
    case close
    case curve(Point, Point, Point)
  }
  public var elements: [Element]
  public var transform: Transform?
  public init() {
    elements = []
  }
  public init(_ string: String, transforms: [String] = [], scale: Float? = nil) throws {
    let split = string.lazy.split(separator: " ")
    var iterator = split.makeIterator()
    self.elements = [Element]()
    while let next = iterator.next() {
      guard next.count > 0 else { continue }
      switch next.first! {
      case "M":
        let point = try next.dropFirst().point() * scale
        elements.append(.move(point))
      case "L":
        let point = try next.dropFirst().point() * scale
        elements.append(.line(point))
      case "Z":
        elements.append(.close)
      case "C":
        let a = try next.dropFirst().point() * scale
        let b = try iterator.tryNext().point() * scale
        let c = try iterator.tryNext().point() * scale
        elements.append(.curve(c, a, b))
      default:
        throw ParsingError.corrupted
      }
    }
    if transforms.count > 0 {
      transform = try Svg.transform(from: transforms)
    }
  }
  public func code() -> String {
    let data = DataWriter()
    data.append(self)
    var string = data.data.compress(.zlib)!.base64()
    string.insert("\n", every: 80)
    return string
  }
}

// MARK: - Svg manager
public struct Svgs {
  public var elements: SortedArray<NamedSvg>
  public init() {
    elements = []
  }
  public init(_ elements: SortedArray<NamedSvg>) {
    self.elements = elements
  }
  public func at(_ name: String) -> Svg? {
    elements.at(name)?.svg
  }
  public func named(at name: String) -> NamedSvg? {
    elements.at(name)
  }
}

public struct NamedSvg: Id {
  public var id: String { name }
  public var name: String
  public var svg: Svg
  public init(name: String, svg: Svg) {
    self.name = name
    self.svg = svg
  }
}

// MARK: - Custom string convertible
extension Svg.Point: CustomStringConvertible {
  fileprivate static func * (l: Self, r: Float?) -> Self {
    guard let r = r else { return l }
    return .init(x: (l.x * r).rounded(.toNearestOrEven), y: (l.y * r).rounded(.toNearestOrEven))
  }
  public var description: String {
    let ix = Int(x)
    let iy = Int(y)
    switch (Float(ix) == x, Float(iy) == y) {
    case (false, false):
      return "\(x),\(y)"
    case (true, false):
      return "\(ix),\(y)"
    case (false, true):
      return "\(x),\(iy)"
    case (true, true):
      return "\(ix),\(iy)"
    }
  }
}
extension Svg: CustomStringConvertible {
  public var description: String {
    elements.lazy.map(\.description).joined(separator: " ")
  }
}
extension Svg.Element: CustomStringConvertible {
  public var description: String {
    switch self {
    case let .move(a):
      return "M\(a)"
    case let .line(a):
      return "L\(a)"
    case .close:
      return "Z"
    case let .curve(c, a, b):
      return "C\(a) \(b) \(c)"
    }
  }
}

// MARK: - DataRepresentable
extension Svg: DataRepresentable {
  public init(data: DataReader) throws {
    elements = try data.next()
    transform = try data.next()
  }
  public func save(data: DataWriter) {
    data.append(elements)
    data.append(transform)
  }
}
extension Svg.Element: DataRepresentable {
  public init(data: DataReader) throws {
    let id = try data.int()
    switch id {
    case 0:
      self = .move(try data.next())
    case 1:
      self = .line(try data.next())
    case 2:
      self = .close
    case 3:
      self = try .curve(data.next(), data.next(), data.next())
    default: throw corrupted
    }
  }
  public func save(data: DataWriter) {
    switch self {
    case let .move(a):
      data.append(0)
      data.append(a)
    case let .line(a):
      data.append(1)
      data.append(a)
    case .close:
      data.append(2)
    case let .curve(a, b, c):
      data.append(3)
      data.append(a)
      data.append(b)
      data.append(c)
    }
  }
}
extension Svg.Transform: DataRepresentable {
  public init(data: DataReader) throws {
    a = try data.next()
    b = try data.next()
    c = try data.next()
    d = try data.next()
    tx = try data.next()
    ty = try data.next()
  }
  public func save(data: DataWriter) {
    data.append(a)
    data.append(b)
    data.append(c)
    data.append(d)
    data.append(tx)
    data.append(ty)
  }
}
extension Svg.Point: DataRepresentable {
  public init(data: DataReader) throws {
    x = try Float(data.int())
    y = try Float(data.int())
  }
  public func save(data: DataWriter) {
    data.append(Int(x.rounded(.toNearestOrEven)))
    data.append(Int(y.rounded(.toNearestOrEven)))
  }
}
extension NamedSvg: DataRepresentable {
  public init(data: DataReader) throws {
    name = try data.next()
    svg = try data.next()
  }
  public func save(data: DataWriter) {
    data.append(name)
    data.append(svg)
  }
}
extension Svgs: DataRepresentable {
  public init(data: DataReader) throws {
    elements = try data.next()
  }
  public func save(data: DataWriter) {
    data.append(elements)
  }
}

// MARK: - Iterator extensions
private extension Substring {
  func double() throws -> Float {
    guard let double = Float(self) else { throw Svg.ParsingError.corrupted }
    return double
  }
  func cgFloat() throws -> Float {
    try double()
  }
  func point() throws -> Svg.Point {
    try split(separator: ",").point()
  }
}
private extension Array where Element == Substring {
  func point() throws -> Svg.Point {
    guard count == 2 else { throw Svg.ParsingError.corrupted }
    return try Svg.Point(x: self[0].double(), y: self[1].double())
  }
}
private extension IndexingIterator {
  mutating func tryNext() throws -> Element {
    guard let value = self.next() else { throw Svg.ParsingError.corrupted }
    return value
  }
}

// MARK: - Core Graphics extensions
#if canImport(CoreGraphics)
import CoreGraphics

private extension IndexingIterator where Element == String {
  mutating func tryDouble() throws -> Float {
    try Float(tryNext()) ?? 0
  }
  mutating func tryPoint() throws -> Svg.Point {
    try .init(x: tryDouble(), y: tryDouble())
  }
}

extension Substring {
  func double() throws -> Double {
    guard let double = Double(self) else { throw Svg.ParsingError.corrupted }
    return double
  }
  func cgPoint() throws -> CGPoint {
    try split(separator: ",").cgPoint()
  }
}
extension Array where Element == Substring {
  func cgPoint() throws -> CGPoint {
    guard count == 2 else { throw Svg.ParsingError.corrupted }
    return try CGPoint(x: self[0].double(), y: self[1].double())
  }
}

public extension Svg.Point {
  init(_ point: CGPoint) {
    self.init(x: Float(point.x), y: Float(point.y))
  }
  var cgPoint: CGPoint {
    CGPoint(x: CGFloat(x), y: CGFloat(y))
  }
}
public extension Svg {
  init(_ path: CGPath) {
    self.init()
    path.applyWithBlock { item in
      let item = item.pointee
      switch item.type {
      case .moveToPoint:
        elements.append(.move(Svg.Point(item.points[0])))
      case .addLineToPoint:
        self.elements.append(.line(Svg.Point(item.points[0])))
      case .closeSubpath:
        elements.append(.close)
      case .addCurveToPoint:
        self.elements.append(.curve(Svg.Point(item.points[0]), Svg.Point(item.points[1]), Svg.Point(item.points[2])))
      default: break
      }
    }
  }
  func path() -> CGPath {
    let path = CGMutablePath()
    let transform = transform?.affineTransform ?? .identity
    elements.forEach {
      switch $0 {
      case let .move(a):
        path.move(to: a.cgPoint, transform: transform)
      case let .line(a):
        path.addLine(to: a.cgPoint, transform: transform)
      case .close:
        path.closeSubpath()
      case let .curve(a, b, c):
        path.addCurve(to: a.cgPoint, control1: b.cgPoint, control2: c.cgPoint, transform: transform)
      }
    }
    return path
  }
  static func transform(from transforms: [String]) throws -> Transform {
    var transformIterator = transforms.makeIterator()
    var transform = CGAffineTransform.identity
    while let next = transformIterator.next() {
      switch next {
      case "translate":
        let a = try transformIterator.tryPoint()
        transform = transform.translatedBy(x: CGFloat(a.x), y: CGFloat(a.y))
      case "scale":
        let a = try transformIterator.tryPoint()
        transform = transform.scaledBy(x: CGFloat(a.x), y: CGFloat(a.y))
      case "rotate":
        let degrees = try transformIterator.tryDouble()
        transform = transform.rotated(by: CGFloat(degrees) / 180 * .pi)
      default:
        print("Unknown transform: \(next)")
        throw ParsingError.corrupted
      }
    }
    return Transform(a: Float(transform.a),
                     b: Float(transform.b),
                     c: Float(transform.c),
                     d: Float(transform.d),
                     tx: Float(transform.tx),
                     ty: Float(transform.ty))
  }
}
extension Svg.Transform {
  var affineTransform: CGAffineTransform {
    CGAffineTransform(a: CGFloat(a), b: CGFloat(b), c: CGFloat(c), d: CGFloat(d), tx: CGFloat(tx), ty: CGFloat(ty))
  }
}
#endif

// MARK: - UIKit extensions
#if canImport(UIKit)
import UIKit
public extension String {
  func svg() -> UIBezierPath? {
    try? Svg(replacingOccurrences(of: "|\n", with: "")).path()
  }
}

extension Svg {
  func path() -> UIBezierPath {
    let path = UIBezierPath()
    elements.forEach {
      switch $0 {
      case let .move(a):
        path.move(to: a.cgPoint)
      case let .line(a):
        path.addLine(to: a.cgPoint)
      case .close:
        path.close()
      case let .curve(a, b, c):
        path.addCurve(to: a.cgPoint, controlPoint1: b.cgPoint, controlPoint2: c.cgPoint)
      }
    }
    if let transform = transform?.affineTransform {
      path.apply(transform)
    }
    path.normalize()
    return path
  }
}

extension UIBezierPath {
  func normalize() {
    let bounds = self.bounds
    apply(CGAffineTransform(translationX: -bounds.origin.x, y: -bounds.origin.y))
  }
}
#endif


#endif
