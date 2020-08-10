//
//  DynamicFrame2.swift
//  Some
//
//  Created by Dmitry on 24/03/2019.
//  Copyright © 2019 Дмитрий Козлов. All rights reserved.
//

import UIKit

public protocol DynamicFrame2 {
  var _dynamicLayout: DynamicLayout? { get set }
  var superview: UIView? { get }
  var parent: UIView? { get }
}
extension DynamicFrame2 {
  var parent: UIView? { return superview }
  var dynamicLayout: DynamicLayout? {
    get {
      return _dynamicLayout
    }
    set {
      _dynamicLayout = newValue
      guard let layout = newValue else { return }
      guard let parent = self.parent else { return }
      guard let view = self as? UIView else { return }
      layout.parent = parent
      layout.updateFrame(child: view)
    }
  }
}
open class DynamicLayout {
  public static func frame(_ frame: @escaping (CGRect)->(CGRect)) -> DynamicLayout {
    return Frame(frame: frame)
  }
  public static func center(_ center: @escaping (CGRect)->(CGPoint)) -> DynamicLayout {
    return Center(center: center)
  }
  public static func pos(_ position: @escaping (CGRect)->(CGPoint, Anchor)) -> DynamicLayout {
    return Position(position: position)
  }
  public static func sframe(_ frame: @escaping ()->(CGRect)) -> DynamicLayout {
    return SFrame(frame: frame)
  }
  public static func scenter(_ center: @escaping ()->(CGPoint)) -> DynamicLayout {
    return SCenter(center: center)
  }
  public static func spos(_ position: @escaping ()->(CGPoint, Anchor)) -> DynamicLayout {
    return SPosition(position: position)
  }
  
  public weak var parent: UIView?
  open func updateFrame(parent: UIView, child: UIView) {
    self.parent = parent
    updateFrame(child: child)
  }
  open func updateFrame(child: UIView) {
    guard let parent = parent else { return }
    let size = child.frame.size
    update(frame: parent.frame, child: child)
    if child.frame.size != size {
      child.resolutionChanged()
    }
  }
  open func update(frame: CGRect, child: UIView) {
    
  }
  public class Center: DynamicLayout {
    public let center: (CGRect) -> CGPoint
    public init(center: @escaping (CGRect) -> (CGPoint)) {
      self.center = center
    }
    public override func update(frame: CGRect, child: UIView) {
      child.center = center(frame)
    }
  }
  public class Frame: DynamicLayout {
    public let frame: (CGRect) -> CGRect
    public init(frame: @escaping (CGRect) -> (CGRect)) {
      self.frame = frame
    }
    public override func update(frame: CGRect, child: UIView) {
      child.frame = self.frame(frame)
    }
  }
  public class Position: DynamicLayout {
    public let position: (CGRect) -> (CGPoint, Anchor)
    public init(position: @escaping (CGRect) -> (CGPoint, Anchor)) {
      self.position = position
    }
    public override func update(frame: CGRect, child: UIView) {
      let (pos,anchor) = position(frame)
      child.move(pos,anchor)
    }
  }
  public class SCenter: DynamicLayout {
    public let center: () -> CGPoint
    public init(center: @escaping () -> (CGPoint)) {
      self.center = center
    }
    public override func update(frame: CGRect, child: UIView) {
      child.center = center()
    }
  }
  public class SFrame: DynamicLayout {
    public let frame: () -> CGRect
    public init(frame: @escaping () -> (CGRect)) {
      self.frame = frame
    }
    public override func update(frame: CGRect, child: UIView) {
      child.frame = self.frame()
    }
  }
  public class SPosition: DynamicLayout {
    public let position: () -> (CGPoint, Anchor)
    public init(position: @escaping () -> (CGPoint, Anchor)) {
      self.position = position
    }
    public override func update(frame: CGRect, child: UIView) {
      let (pos,anchor) = position()
      child.move(pos,anchor)
    }
  }
}


//// MARK:- UIView
//open class DView: UIView, DynamicFrame2 {
//  public var _dynamicLayout: DynamicLayout?
//  
//  public class func dfvline(_ pos: Pos, anchor: Anchor, height: CGFloat, color: UIColor) -> DFView {
//    let view = DFView(frame: CGRect(pos, anchor, Size(screen.pixel, height)))
//    view.dframe = { CGRect(pos, anchor, Size(screen.pixel, height)) }
//    view.backgroundColor = color
//    return view
//  }
//  public class func dfhline(_ pos: Pos, anchor: Anchor, width: CGFloat, color: UIColor) -> DFView {
//    let view = DFView(frame: CGRect(pos, anchor, Size(width, screen.pixel)))
//    view.dframe = { CGRect(pos, anchor, Size(width, screen.pixel)) }
//    view.backgroundColor = color
//    return view
//  }
//}
//
//// MARK:- UILabel
//open class DFLabel: UILabel, DynamicFrame {
//  public var dynamicFrame: DFrame?
//}
//
//open class DPLabel: UILabel, DynamicPos {
//  public var _dynamicLayout: DynamicLayout?
//  public var dpos: DPos? { didSet { updateFrame() } }
//  public var maxSize: (()->(CGSize))?
//  open func set(text: String) {
//    self.text = text
//    guard let (_,anchor) = dpos?() else { return }
//    resize(text.size(font), anchor)
//  }
//  public func updateFrame() {
//    var frame = self.frame
//    if let maxSize = maxSize?() {
//      if maxSize.width > 0 {
//        frame.w = maxSize.width
//      }
//      if maxSize.height > 0 && numberOfLines != 1 {
//        frame.h = min(maxSize.height,text!.height(font, width: frame.w))
//      }
//    }
//    guard let dpos = self.dpos else { return }
//    let (pos,anchor) = dpos()
//    frame.move(pos, anchor)
//    self.frame = frame
//  }
//}
//
//open class DCLabel: UILabel, DynamicCenter {
//  public var dcenter: DCenter? { didSet { updateFrame() } }
//  open func set(text: String) {
//    self.text = text
//    resize(text.size(font), .center)
//  }
//}
//
//// MARK:- UISwitch
//open class DFSwitch: UISwitch, DynamicFrame {
//  public var dynamicFrame: DFrame?
//}
//
//open class DPSwitch: UISwitch, DynamicPos {
//  public var dpos: DPos? { didSet { updateFrame() } }
//}
//
//// MARK:- UITextField
//open class DFTextField: UITextField, DynamicFrame {
//  public var dynamicFrame: DFrame?
//}
//
//open class DPTextField: UITextField, DynamicPos {
//  public var dpos: DPos? { didSet { updateFrame() } }
//}
//
//// MARK:- UITextView
//open class DFTextView: UITextView, DynamicFrame {
//  public var dynamicFrame: DFrame?
//}
//
//open class DPTextView: UITextView, DynamicPos {
//  public var dpos: DPos? { didSet { updateFrame() } }
//}
//
//// MARK:- UISearchBar
//open class DFSearchBar: UISearchBar, DynamicFrame {
//  public var dynamicFrame: DFrame?
//}
//
//open class DPSearchBar: UISearchBar, DynamicPos {
//  public var dpos: DPos? { didSet { updateFrame() } }
//}
//
//// MARK:- UIImageView
//open class DFImageView: UIImageView, DynamicFrame {
//  public var dynamicFrame: DFrame?
//}
//
//open class DPImageView: UIImageView, DynamicPos {
//  public var dpos: DPos? { didSet { updateFrame() } }
//}
//
//open class DCImageView: UIImageView, DynamicCenter {
//  public var dcenter: DCenter? { didSet { updateFrame() } }
//}
//
//// MARK:- UIButton
//open class DFButton: UIButton, DynamicFrame {
//  public var dynamicFrame: DFrame?
//}
//
//open class DPButton: UIButton, DynamicPos {
//  public var dpos: DPos? { didSet { updateFrame() } }
//}
//
//open class DCButton: UIButton, DynamicCenter {
//  public var dcenter: DCenter? { didSet { updateFrame() } }
//}
//
//// MARK:- UIScrollView
//open class DFScrollView: UIScrollView2, DynamicFrame {
//  public var dynamicFrame: DFrame?
//}
//
//open class DPScrollView: UIScrollView2, DynamicPos {
//  public var dpos: DPos? { didSet { updateFrame() } }
//}
//
//// MARK:- UIVisualEffectView
//open class DFVisualEffectView: UIVisualEffectView, DynamicFrame {
//  public var dynamicFrame: DFrame?
//}
//
//open class DPVisualEffectView: UIVisualEffectView, DynamicPos {
//  public var dpos: DPos? { didSet { updateFrame() } }
//}
//
//open class DCVisualEffectView: UIVisualEffectView, DynamicCenter {
//  public var dcenter: DCenter? { didSet { updateFrame() } }
//}
