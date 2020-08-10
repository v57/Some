#if os(iOS)
//
//  Constraints.swift
//  Some
//
//  Created by Dmitry on 27/09/2019.
//  Copyright © 2019 Дмитрий Козлов. All rights reserved.
//

import UIKit

//.lr(16.. | view)
//.lr(16..)
//.lr(16.. | superview)
//.lr(16.. ~ superview)

infix operator ~
postfix operator ~
prefix operator ..
prefix operator >
postfix operator ..

private typealias Measure = ConstraintsMeasure
private typealias Comparsion = Constraints.ComparsionType
public class ConstraintsMeasure: ExpressibleByFloatLiteral {
  public typealias ComparsionType = Constraints.ComparsionType
  var offset: CGFloat { shouldInvert ? -_offset : _offset }
  var comparsion: ComparsionType { shouldInvert ? _comparsion.inverted : _comparsion }
  
  var view: UIView { constraints.v }
  var right: UIView?
  var constraints: Constraints!
  
  private let _offset: CGFloat
  var _comparsion: ComparsionType
  var safeArea = false
  var invert = false
  var ignoreInvert = false
  var shouldInvert: Bool { invert && !ignoreInvert }
  required public init(floatLiteral value: Double) {
    _offset = CGFloat(value)
    _comparsion = .equal
  }
  init(offset: CGFloat, comparsion: ComparsionType) {
    _offset = offset
    _comparsion = comparsion
  }
  init(_ offset: CGFloat, _ comparsion: ComparsionType = .equal) {
    _offset = offset
    _comparsion = comparsion
  }
  init(_ offset: Double, _ comparsion: ComparsionType = .equal) {
    _offset = CGFloat(offset)
    _comparsion = comparsion
  }
}
public extension Double {
  static prefix func ..(l: Double) -> ConstraintsMeasure {
    ConstraintsMeasure(l, .less)
  }
  static prefix func >(l: Double) -> ConstraintsMeasure {
    ConstraintsMeasure(l, .greater)
  }
  static postfix func ..(l: Double) -> ConstraintsMeasure {
    ConstraintsMeasure(l, .greater)
  }
  static postfix func ~(l: Double) -> ConstraintsMeasure {
    ConstraintsMeasure(l)~
  }
}
public extension ConstraintsMeasure {
  static func |(l: ConstraintsMeasure, r: UIView) -> ConstraintsMeasure {
    l.right = r
    return l
  }
  static prefix func ~(l: ConstraintsMeasure) -> ConstraintsMeasure {
    l.invert = true
    return l
  }
  static postfix func ~(l: ConstraintsMeasure) -> ConstraintsMeasure {
    l.safeArea = true
    return l
  }
  static func ~(l: ConstraintsMeasure, r: UIView) -> ConstraintsMeasure {
    l.right = r
    l.safeArea = true
    return l
  }
  static prefix func >(l: ConstraintsMeasure) -> ConstraintsMeasure {
    l._comparsion = .greater
    return l
  }
  static prefix func ..(l: ConstraintsMeasure) -> ConstraintsMeasure {
    l._comparsion = .less
    return l
  }
  static postfix func ..(l: ConstraintsMeasure) -> ConstraintsMeasure {
    l._comparsion = .greater
    return l
  }
}
private extension ConstraintsMeasure {
  var layout: AutoLayout {
    let view = self.right ?? self.constraints.s
    if safeArea {
      return view.sa
    } else {
      return view
    }
  }
  
  func set(_ constraints: Constraints) -> Self {
    self.constraints = constraints
    return self
  }
  func convert(_ alignment: Alignment) -> Alignment {
    return right == nil ? alignment : alignment.inverted
  }
  func x(_ a1: Alignment, _ a2: Alignment) {
    set(view.x(a1), layout.x(convert(a2)))
  }
  func y(_ a1: Alignment, _ a2: Alignment) {
    set(view.y(a1), layout.y(convert(a2)))
  }
  func s(_ a1: Dimension, _ a2: Dimension) {
    set(view.d(a1), layout.d(a2))
  }
  func eq(_ a1: Dimension) {
    set(view.d(a1))
  }
  
  func set<T>(_ a1: NSLayoutAnchor<T>, _ a2: NSLayoutAnchor<T>) {
    switch comparsion {
    case .less:
      constraints.append(a1.constraint(lessThanOrEqualTo: a2, constant: offset))
    case .greater:
      constraints.append(a1.constraint(greaterThanOrEqualTo: a2, constant: offset))
    case .equal:
      constraints.append(a1.constraint(equalTo: a2, constant: offset))
    }
  }
  func set(_ a: NSLayoutDimension) {
    switch comparsion {
    case .less:
      constraints.append(a.constraint(lessThanOrEqualToConstant: offset))
    case .greater:
      constraints.append(a.constraint(greaterThanOrEqualToConstant: offset))
    case .equal:
      constraints.append(a.constraint(equalToConstant: offset))
    }
  }
}

public class Constraints {
  public let v: UIView
  public var superview: UIView?
  public var s: UIView { superview ?? v.superview! }
  public var isActive = true {
    didSet {
      guard isActive != oldValue else { return }
      if isActive {
        NSLayoutConstraint.activate(constraints)
      } else {
        NSLayoutConstraint.deactivate(constraints)
      }
    }
  }
  public var constraints = [NSLayoutConstraint]()
  public var constraint: NSLayoutConstraint { constraints.last! }
  public var priority: UILayoutPriority?
  
  public init(view: UIView) {
    self.v = view
  }
}

private extension Constraints {
  func x(_ measure: Measure, _ a1: Alignment, _ a2: Alignment) -> Self {
    measure.set(self).x(a1, a2)
    return self
  }
  func y(_ measure: Measure, _ a1: Alignment, _ a2: Alignment) -> Self {
    measure.set(self).y(a1, a2)
    return self
  }
  func s(_ measure: Measure, _ a1: Dimension, _ a2: Dimension) -> Self {
    measure.set(self).s(a1, a2)
    return self
  }
  func eq(_ measure: Measure, _ a1: Dimension) -> Self {
    measure.set(self).eq(a1)
    return self
  }
  func x(_ measure: Measure, _ a: Alignment) -> Self {
    measure.set(self).x(a, a)
    return self
  }
  func y(_ measure: Measure, _ a: Alignment) -> Self {
    measure.set(self).y(a, a)
    return self
  }
  func s(_ measure: Measure, _ a: Dimension) -> Self {
    measure.set(self).s(a, a)
    return self
  }
}

public extension Constraints {
  @discardableResult func l(_ measure: Measure) -> Self {
    x(measure, .left)
  }
  @discardableResult func r(_ measure: Measure) -> Self {
    x(measure, .right)
  }
  @discardableResult func lr(_ measure: Measure) -> Self {
    l(measure).r(measure)
  }
  @discardableResult func cx(_ measure: Measure) -> Self {
    x(measure, .center)
  }
  @discardableResult func t(_ measure: Measure) -> Self {
    x(measure, .top)
  }
  @discardableResult func b(_ measure: Measure) -> Self {
    x(measure, .bottom)
  }
  @discardableResult func tb(_ measure: Measure) -> Self {
    t(measure).b(measure)
  }
  @discardableResult func cy(_ measure: Measure) -> Self {
    x(measure, .center)
  }
  
  @discardableResult func tr(_ measure: Measure) -> Self {
    t(measure).r(measure)
  }
  @discardableResult func tl(_ measure: Measure) -> Self {
    t(measure).l(measure)
  }
  @discardableResult func br(_ measure: Measure) -> Self {
    b(measure).r(measure)
  }
  @discardableResult func bl(_ measure: Measure) -> Self {
    b(measure).l(measure)
  }
  
  @discardableResult func w(_ measure: Measure) -> Self {
    s(measure, .width)
  }
  @discardableResult func h(_ measure: Measure) -> Self {
    s(measure, .height)
  }
  @discardableResult func wh(_ measure: Measure) -> Self {
    s(measure, .width, .height)
  }
  @discardableResult func hw(_ measure: Measure) -> Self {
    s(measure, .height, .width)
  }
}

public extension Constraints {
  typealias Measure = ConstraintsMeasure
  func `switch`() -> ConstraintsSwitch {
    return ConstraintsSwitch(self)
  }
  func toggle(with constraints: Constraints) -> ConstraintsSwitch {
    return ConstraintsSwitch(self, constraints)
  }
  func activated() -> Self {
    isActive = true
    return self
  }
  func deactivated() -> Self {
    isActive = false
    return self
  }
  func priority(_ priority: UILayoutPriority) -> Self {
    self.priority = priority
    return self
  }
  func set(_ superview: UIView) -> Self {
    self.superview = superview
    return self
  }
  fileprivate func append(_ constraint: NSLayoutConstraint) {
    if let priority = priority {
      constraint.priority = priority
    }
    constraint.isActive = isActive
    constraints.append(constraint)
  }
  private func make(_ a: NSLayoutXAxisAnchor, _ b: NSLayoutXAxisAnchor, _ offset: CGFloat, _ invert: Bool, _ compare: C) -> Self {
    var compare = compare(self,self)
    var offset = offset
    if invert {
      compare = compare.inverted
      offset = -offset
    }
    switch compare {
    case .less:
      append(a.constraint(lessThanOrEqualTo: b, constant: offset))
    case .greater:
      append(a.constraint(greaterThanOrEqualTo: b, constant: offset))
    case .equal:
      append(a.constraint(equalTo: b, constant: offset))
    }
    return self
  }
  private func make(_ a: NSLayoutDimension, _ offset: CGFloat, _ compare: C) -> Self {
    let compare = compare(self,self)
    switch compare {
    case .less:
      append(a.constraint(lessThanOrEqualToConstant: offset))
    case .greater:
      append(a.constraint(greaterThanOrEqualToConstant: offset))
    case .equal:
      append(a.constraint(equalToConstant: offset))
    }
    return self
  }
  private func make(_ a: NSLayoutDimension, _ b: NSLayoutDimension, _ offset: CGFloat, _ compare: C) -> Self {
    let compare = compare(self,self)
    switch compare {
    case .less:
      append(a.constraint(lessThanOrEqualTo: b, constant: offset))
    case .greater:
      append(a.constraint(greaterThanOrEqualTo: b, constant: offset))
    case .equal:
      append(a.constraint(equalTo: b, constant: offset))
    }
    return self
  }
  private func make(_ a: NSLayoutYAxisAnchor, _ b: NSLayoutYAxisAnchor, _ offset: CGFloat, _ invert: Bool, _ compare: C) -> Self {
    var compare = compare(self,self)
    var offset = offset
    if invert {
      compare = compare.inverted
      offset = -offset
    }
    switch compare {
    case .less:
      append(a.constraint(lessThanOrEqualTo: b, constant: offset))
    case .greater:
      append(a.constraint(greaterThanOrEqualTo: b, constant: offset))
    case .equal:
      append(a.constraint(equalTo: b, constant: offset))
    }
    return self
  }
  @discardableResult func fs() -> Self {
    return lr().tb()
  }
  @discardableResult func fs(_ insets: UIEdgeInsets) -> Self {
    l(insets.left).r(insets.right).t(insets.top).b(insets.bottom)
  }
  @discardableResult func fs(_ view: UIView, _ c: C = Constraints.e) -> Self {
    return make(v.t, view.t, 0, false, c).make(v.l, view.l, 0, false, c).w(view).h(view)
  }
  @discardableResult func sfs() -> Self {
    return sl().sr().st().sb()
  }
  /// Center X to superview center x with offset
  @discardableResult func cx(_ o: CGFloat = 0, _ c: C = Constraints.e) -> Self {
    return make(v.cx, s.cx, o, false, c)
  }
  /// Center X to view's center x with offset
  @discardableResult func cx(_ o: CGFloat, _ view: UIView, _ c: C = Constraints.e) -> Self {
    return make(v.cx, view.cx, o, false, c)
  }
  /// Center X to view's center x
  @discardableResult func cx(_ view: UIView, _ c: C = Constraints.e) -> Self {
    return make(v.cx, view.cx, 0, false, c)
  }
  /// Center Y to superview center y with offset
  @discardableResult func cy(_ o: CGFloat = 0, _ c: C = Constraints.e) -> Self {
    return make(v.cy, s.cy, o, false, c)
  }
  /// Center Y to view's center y with offset
  @discardableResult func cy(_ o: CGFloat, _ view: UIView, _ c: C = Constraints.e) -> Self {
    return make(v.cy, view.cy, o, false, c)
  }
  /// Center Y to view's center y
  @discardableResult func cy(_ view: UIView, _ c: C = Constraints.e) -> Self {
    return make(v.cy, view.cy, 0, false, c)
  }
  /// Center to superview center
  @discardableResult func c(_ c: C = Constraints.e) -> Self {
    return cx(0, c).cy(0, c)
  }
  /// Top to superview safe area top with offset
  @discardableResult func st(_ o: CGFloat = 0, _ c: C = Constraints.e) -> Self {
    return make(v.t, s.sa.t, o, false, c)
  }
  /// Top to superview top with offset
  @discardableResult func t(_ o: CGFloat = 0, _ c: C = Constraints.e) -> Self {
    return make(v.t, s.t, o, false, c)
  }
  @discardableResult func t(_ g: NSLayoutYAxisAnchor, _ c: C = Constraints.e) -> Self {
    return make(v.t, g, 0, false, c)
  }
  @discardableResult func t(_ o: CGFloat, _ g: NSLayoutYAxisAnchor, _ c: C = Constraints.e) -> Self {
    return make(v.t, g, o, false, c)
  }
  /// Bottom to superview safe area bottom with negative offset
  @discardableResult func sb(_ o: CGFloat = 0, _ c: C = Constraints.e) -> Self {
    return make(v.b, s.sa.b, o, true, c)
  }
  /// Bottom to view top with negative offset
  @discardableResult func b(_ o: CGFloat = 0, _ c: C = Constraints.e) -> Self {
    return make(v.b, s.b, o, true, c)
  }
  @discardableResult func b(_ g: NSLayoutYAxisAnchor, _ c: C = Constraints.e) -> Self {
    return make(v.b, g, 0, false, c)
  }
  @discardableResult func b(_ o: CGFloat, _ g: NSLayoutYAxisAnchor, _ c: C = Constraints.e) -> Self {
    return make(v.b, g, o, false, c)
  }
  /// Width
  @discardableResult func w(_ o: CGFloat, _ c: C = Constraints.e) -> Self {
    return make(v.w, o, c)
  }
  /// Width
  @discardableResult func w(_ o: CGFloat, _ view: UIView, _ c: C = Constraints.e) -> Self {
    return make(v.w, view.w, o, c)
  }
  /// Width
  @discardableResult func w(_ view: UIView, _ c: C = Constraints.e) -> Self {
    return make(v.w, view.w, 0, c)
  }
  /// Width equal to height
  @discardableResult func wh(_ c: C = Constraints.e) -> Self {
    return make(v.w, v.h, 0, c)
  }
  /// Width and Height
  @discardableResult func wh(_ s: CGFloat, _ c: C = Constraints.e) -> Self {
    return w(s, c).h(s, c)
  }
  /// Height
  @discardableResult func h(_ o: CGFloat, _ c: C = Constraints.e) -> Self {
    return make(v.h, o, c)
  }
  /// Height
  @discardableResult func h(_ o: CGFloat, _ view: UIView, _ c: C = Constraints.e) -> Self {
    return make(v.h, view.h, o, c)
  }
  /// Height
  @discardableResult func h(_ view: UIView, _ c: C = Constraints.e) -> Self {
    return make(v.h, view.h, 0, c)
  }
  /// Height equal to width
  @discardableResult func hw(_ c: C = Constraints.e) -> Self {
    return make(v.h, v.w, 0, c)
  }
  /// Size
  @discardableResult func s(_ size: CGSize) -> Self {
    return w(size.width).h(size.height)
  }
  /// Left to superview left with offset
  @discardableResult func l(_ o: CGFloat = 0, _ c: C = Constraints.e) -> Self {
    return make(v.l, s.l, o, false, c)
  }
  /// Top to superview safe area top with offset
  @discardableResult func sl(_ o: CGFloat = 0, _ c: C = Constraints.e) -> Self {
    return make(v.l, s.sa.l, o, false, c)
  }
  /// Right to superview right with negative offset
  @discardableResult func r(_ o: CGFloat = 0, _ c: C = Constraints.e) -> Self {
    return make(v.r, s.r, o, true, c)
  }
  /// Right to superview right with negative offset
  @discardableResult func sr(_ o: CGFloat = 0, _ c: C = Constraints.e) -> Self {
    return make(v.r, s.sa.r, o, true, c)
  }
  @discardableResult func tr(_ o: CGFloat = 0, _ c: C = Constraints.e) -> Self {
    return t(o,c).r(o,c)
  }
  /// Left and right to superview left and right with offset
  @discardableResult func lr(_ o: CGFloat = 0, _ c: C = Constraints.e) -> Self {
    return l(o, c).r(o, c)
  }
  @discardableResult func slr(_ o: CGFloat = 0, _ c: C = Constraints.e) -> Self {
    return sl(o, c).sr(o, c)
  }
  /// Top and bottom to superview top and bottom with offset
  @discardableResult func tb(_ o: CGFloat = 0, _ c: C = Constraints.e) -> Self {
    return t(o, c).b(o, c)
  }
  
  // MARK: Constraints to view
  /// Left to view right with offset
  @discardableResult func l(_ o: CGFloat = 0, _ view: UIView, _ c: C = Constraints.e) -> Self {
    return make(v.l, view.r, o, false, c)
  }
  /// Left to view right
  @discardableResult func l(_ view: UIView, _ c: C = Constraints.e) -> Self {
    return make(v.l, view.r, 0, false, c)
  }
  /// Right to view left with negative offset
  @discardableResult func r(_ o: CGFloat = 0, _ view: UIView, _ c: C = Constraints.e) -> Self {
    return make(v.r, view.l, o, true, c)
  }
  /// Right to view left
  @discardableResult func r(_ view: UIView, _ c: C = Constraints.e) -> Self {
    return make(v.r, view.l, 0, true, c)
  }
  /// Bottom to view top with negative offset
  @discardableResult func b(_ o: CGFloat, _ view: UIView, _ c: C = Constraints.e) -> Self {
    return make(v.b, view.t, o, true, c)
  }
  /// Bottom to view top
  @discardableResult func b(_ view: UIView, _ c: C = Constraints.e) -> Self {
    return make(v.b, view.t, 0, true, c)
  }
  /// Top to view top with offset
  @discardableResult func t(_ o: CGFloat, _ view: UIView, _ c: C = Constraints.e) -> Self {
    return make(v.t, view.b, o, false, c)
  }
  /// Top to view top
  @discardableResult func t(_ view: UIView, _ c: C = Constraints.e) -> Self {
    return make(v.t, view.b, 0, false, c)
  }
}
// MARK: Comparsion functions
public extension Constraints {
  typealias C = (Constraints,Constraints)->ComparsionType
  enum ComparsionType {
    case less, greater, equal
    var inverted: ComparsionType {
      switch self {
      case .less: return .greater
      case .greater: return .less
      case .equal: return .equal
      }
    }
  }
  static func e(a: Constraints, b: Constraints) -> Constraints.ComparsionType {
    return .equal
  }
  static func ==(a: Constraints, b: Constraints) -> ComparsionType {
    return .equal
  }
  static func >(a: Constraints, b: Constraints) -> ComparsionType {
    return .greater
  }
  static func <(a: Constraints, b: Constraints) -> ComparsionType {
    return .less
  }
}

// MARK: UIView Extensions
public extension UIView {
  @discardableResult
  func _build(_ view: UIView) -> Constraints {
    view.translatesAutoresizingMaskIntoConstraints = false
    addSubview(view)
    return Constraints(view: view)
  }
  func build() -> Constraints {
    translatesAutoresizingMaskIntoConstraints = false
    return Constraints(view: self)
  }
  func wh(_ s: CGFloat) -> Self {
    build().wh(s)
    return self
  }
  func w(_ w: CGFloat) -> Self {
    build().w(w)
    return self
  }
  func h(_ h: CGFloat) -> Self {
    build().h(h)
    return self
  }
}

protocol AutoLayout: class {
  var centerXAnchor: NSLayoutXAxisAnchor { get }
  var centerYAnchor: NSLayoutYAxisAnchor { get }
  var topAnchor: NSLayoutYAxisAnchor { get }
  var bottomAnchor: NSLayoutYAxisAnchor { get }
  var leftAnchor: NSLayoutXAxisAnchor { get }
  var rightAnchor: NSLayoutXAxisAnchor { get }
  var widthAnchor: NSLayoutDimension { get }
  var heightAnchor: NSLayoutDimension { get }
}

private extension AutoLayout {
  var cx: LayoutX { centerXAnchor }
  var l: LayoutX { leftAnchor }
  var r: LayoutX { rightAnchor }
  
  var cy: LayoutY { centerYAnchor }
  var t: LayoutY { topAnchor }
  var b: LayoutY { bottomAnchor }
  
  var w: LayoutD { widthAnchor }
  var h: LayoutD { heightAnchor }
  func x(_ alignment: Alignment) -> LayoutX {
    switch alignment {
    case .left: return leftAnchor
    case .right: return rightAnchor
    case .center: return centerXAnchor
    }
  }
  func y(_ alignment: Alignment) -> LayoutY {
    switch alignment {
    case .left: return topAnchor
    case .right: return bottomAnchor
    case .center: return centerYAnchor
    }
  }
  func d(_ dimension: Dimension) -> LayoutD {
    switch dimension {
    case .width: return widthAnchor
    case .height: return heightAnchor
    }
  }
}

private enum Alignment {
  case left, center, right
  static var top: Alignment { left }
  static var bottom: Alignment { right }
  var inverted: Alignment {
    switch self {
    case .left: return .right
    case .right: return .left
    case .center: return self
    }
  }
}
private enum Dimension {
  case width, height
}
typealias LayoutX = NSLayoutXAxisAnchor
typealias LayoutY = NSLayoutYAxisAnchor
typealias LayoutD = NSLayoutDimension
struct LayoutPosition {
  let x: LayoutX
  let y: LayoutY
}

 
// MARK: LayoutAnchors
extension UIView: AutoLayout {
  var sa: UILayoutGuide {
    if #available(iOS 11.0, *) {
      return safeAreaLayoutGuide
    } else {
      return layoutMarginsGuide
    }
  }
}
extension UILayoutGuide: AutoLayout {}

// MARK: NSLayoutConstraint Extensions
public extension NSLayoutConstraint {
  @discardableResult
  func activate() -> Self {
    isActive = true
    return self
  }
  @discardableResult
  func deactivate() -> Self {
    isActive = false
    return self
  }
}

// MARK: ConstraintsSwitch
final public class ConstraintsSwitch {
  public var state: Bool = false {
    didSet {
      guard state != oldValue else { return }
      if state {
        left.isActive = false
        right?.isActive = true
      } else {
        right?.isActive = false
        left.isActive = true
      }
    }
  }
  public var left: Constraints
  public var right: Constraints!
  public init(_ left: Constraints) {
    self.left = left
    self.right = nil
  }
  public init(_ left: Constraints, _ right: Constraints) {
    self.left = left
    self.right = right
  }
  public func toggle() {
    state.toggle()
  }
  public func with(_ view: UIView) -> Constraints {
    right = Constraints(view: view)
    right.isActive = state
    return right
  }
  public func with() -> Constraints {
    right = Constraints(view: left.v)
    right.isActive = state
    return right
  }
}
#endif
