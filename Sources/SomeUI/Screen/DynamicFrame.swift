#if os(iOS)
//
//  dpos.swift
//  stickchat-swift
//
//  Copyright © 2016 OMMG Technologies. All rights reserved.
//

import UIKit

extension Pos {
  public var left: (Pos,Anchor) { return (self,.left) }
  public var topLeft: (Pos,Anchor) { return (self,.topLeft) }
  public var top: (Pos,Anchor) { return (self,.top) }
  public var topRight: (Pos,Anchor) { return (self,.topRight) }
  public var right: (Pos,Anchor) { return (self,.right) }
  public var bottomRight: (Pos,Anchor) { return (self,.bottomRight) }
  public var bottom: (Pos,Anchor) { return (self,.bottom) }
  public var bottomLeft: (Pos,Anchor) { return (self,.bottomLeft) }
  public var center: (Pos,Anchor) { return (self,.center) }
}

public typealias DFrame = ()->CGRect
public typealias DPos = ()->(Pos,Anchor)
public typealias DCenter = ()->Pos

/**
 
 notes:
 frame changes, then calls resolutionChanged()
 
 you can apply multiple protocols
 first non-nil function will be executed
 priorities: DynamicFrame, DynamicPos, DynamicCenter
 so if you class conforms DynamicFrame and DynamicCenter protocols
 and he has dframe and dcenter functions
 only dframe function will be executed on changing resolution
 
 */

/** sample DynamicPos
 open class DPView: UIView, DynamicPos {
 public var dpos: DPos? { didSet { updateFrame() } }
 }
 */

public protocol DynamicPos: class {
  var dpos: DPos? { get set }
  func move(_ pos: Pos, _ anchor: Anchor)
}

extension DynamicPos {
  public func updateFrame() {
    guard let dpos = self.dpos else { return }
    let (pos,anchor) = dpos()
    move(pos,anchor) // красuво
  }
}

public protocol DynamicFrame: class {
  var frame: CGRect { get set }
  var dynamicFrame: DFrame? { get set }
  func resolutionChanged()
}

extension DynamicFrame {
  public var dframe: DFrame? {
    get { dynamicFrame }
    set {
      dynamicFrame = newValue
      updateFrame()
    }
  }
  public func updateFrame() {
    guard let frame = dframe?() else { return }
    let oldSize = self.frame.size
    self.frame = frame
    if oldSize != frame.size {
      resolutionChanged()
    }
  }
}

/** sample DynamicCenter
 open class DCView: UIView, DynamicCenter {
 public var dcenter: DCenter? { didSet { updateFrame() } }
 }
 */

public protocol DynamicCenter: class {
  var dcenter: DCenter? { get set }
  var center: CGPoint { get set }
}

extension DynamicCenter {
  public func updateFrame() {
    guard let center = dcenter?() else { return }
    self.center = center
  }
}

// MARK:- UIView
open class DFView: UIView, DynamicFrame {
  public var dynamicFrame: DFrame?
  
  public class func dfvline(_ pos: Pos, anchor: Anchor, height: CGFloat, color: UIColor) -> DFView {
    let view = DFView(frame: CGRect(pos, anchor, Size(screen.pixel, height)))
    view.dframe = { CGRect(pos, anchor, Size(screen.pixel, height)) }
    view.backgroundColor = color
    return view
  }
  public class func dfhline(_ pos: Pos, anchor: Anchor, width: CGFloat, color: UIColor) -> DFView {
    let view = DFView(frame: CGRect(pos, anchor, Size(width, screen.pixel)))
    view.dframe = { CGRect(pos, anchor, Size(width, screen.pixel)) }
    view.backgroundColor = color
    return view
  }
}

open class DPView: UIView, DynamicPos {
  public var dpos: DPos? { didSet { updateFrame() } }
}


open class DCView: UIView, DynamicCenter {
  public var dcenter: DCenter? { didSet { updateFrame() } }
}

// MARK:- UILabel
open class DFLabel: UILabel, DynamicFrame {
  public var dynamicFrame: DFrame?
}

open class DPLabel: UILabel, DynamicPos {
  public var dpos: DPos? { didSet { updateFrame() } }
  public var maxSize: (()->(CGSize))?
  open func set(text: String) {
    self.text = text
    guard let (_,anchor) = dpos?() else { return }
    resize(text.size(font), anchor)
  }
  public func updateFrame() {
    var frame = self.frame
    if let maxSize = maxSize?() {
      if maxSize.width > 0 {
        frame.w = maxSize.width
      }
      if maxSize.height > 0 && numberOfLines != 1 {
        frame.h = min(maxSize.height,text!.height(font, width: frame.w))
      }
    }
    guard let dpos = self.dpos else { return }
    let (pos,anchor) = dpos()
    frame.move(pos, anchor)
    self.frame = frame
  }
}

open class DCLabel: UILabel, DynamicCenter {
  public var dcenter: DCenter? { didSet { updateFrame() } }
  open func set(text: String) {
    self.text = text
    resize(text.size(font), .center)
  }
}

// MARK:- UISwitch
open class DFSwitch: UISwitch, DynamicFrame {
  public var dynamicFrame: DFrame?
}

open class DPSwitch: UISwitch, DynamicPos {
  public var dpos: DPos? { didSet { updateFrame() } }
}

// MARK:- UITextField
open class DFTextField: UITextField, DynamicFrame {
  public var dynamicFrame: DFrame?
}

open class DPTextField: UITextField, DynamicPos {
  public var dpos: DPos? { didSet { updateFrame() } }
}

// MARK:- UITextView
open class DFTextView: UITextView, DynamicFrame {
  public var dynamicFrame: DFrame?
}

open class DPTextView: UITextView, DynamicPos {
  public var dpos: DPos? { didSet { updateFrame() } }
}

// MARK:- UISearchBar
open class DFSearchBar: UISearchBar, DynamicFrame {
  public var dynamicFrame: DFrame?
}

open class DPSearchBar: UISearchBar, DynamicPos {
  public var dpos: DPos? { didSet { updateFrame() } }
}

// MARK:- UIImageView
open class DFImageView: UIImageView, DynamicFrame {
  public var dynamicFrame: DFrame?
}

open class DPImageView: UIImageView, DynamicPos {
  public var dpos: DPos? { didSet { updateFrame() } }
}

open class DCImageView: UIImageView, DynamicCenter {
  public var dcenter: DCenter? { didSet { updateFrame() } }
}

// MARK:- UIButton
open class DFButton: UIButton, DynamicFrame {
  public var dynamicFrame: DFrame?
}

open class DPButton: UIButton, DynamicPos {
  public var dpos: DPos? { didSet { updateFrame() } }
}

open class DCButton: UIButton, DynamicCenter {
  public var dcenter: DCenter? { didSet { updateFrame() } }
}

// MARK:- UIScrollView
open class DFScrollView: UIScrollView2, DynamicFrame {
  public var dynamicFrame: DFrame?
}

open class DPScrollView: UIScrollView2, DynamicPos {
  public var dpos: DPos? { didSet { updateFrame() } }
}

// MARK:- UIVisualEffectView
open class DFVisualEffectView: UIVisualEffectView, DynamicFrame {
  public var dynamicFrame: DFrame?
}

open class DPVisualEffectView: UIVisualEffectView, DynamicPos {
  public var dpos: DPos? { didSet { updateFrame() } }
}

open class DCVisualEffectView: UIVisualEffectView, DynamicCenter {
  public var dcenter: DCenter? { didSet { updateFrame() } }
}
#endif
