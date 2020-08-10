#if os(iOS)

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

import UIKit
import SomeFunctions

public enum UnloadType {
  case none, memoryWarning, background, offScreen
}

open class SomePage: UIView, DynamicFrame {
  static var main: SomeMain { SomeUI.main! }
  var main: SomeMain { SomeUI.main! }
  public static var test: ()->(SomePage?) = { nil }
  
  public var dynamicFrame: DFrame? = screen.dframe
  open var screenFrame: DFrame {
    return screen.dframe
  }
  open var isFullscreen: Bool {
    return true
  }
  
  public var overlay: PageOverlay?
  open var transition: PageTransition = .default()
  var _background: PageBackground = .none
  public var background: PageBackground {
    get {
      return _background
    } set {
      set(background: newValue, animated: false)
    }
  }
  var pageSwiper: PageSwiper?
  var scrollViewSwiper: PageScrollViewSwiper?
  open var areSwipesEnabled: Bool {
    return true
  }
  
  public internal(set) var isClosing = false
  public internal(set) var isClosed = false
  public internal(set) var firstShow = true
  
  public var title: String = ""
  public var unloadType = UnloadType.none
  public var leftButtonImage: UIImage?
  public var rightButtonImage: UIImage?
  public var showsBackButton = true
  public var showsNavigationBar = SomeSettings.showsNavigationBar
  public var statusBarWhite = SomeSettings.statusBarWhite
  public var showsStatusBar = SomeSettings.showsStatusBar
  
  public init() {
    super.init(frame: screen.frame)
    
    SomeDebug.pages.append(self)
    SomeDebug.pagesInited += 1
    clipsToBounds = true
  }
  
  required public init?(coder aDecoder: NSCoder) {
    super.init(coder: aDecoder)
    SomeDebug.pagesInited += 1
  }
  
  deinit {
    SomeDebug.pagesDeinited += 1
  }
  
  open func leftButtonSelected(){}
  open func rightButtonSelected(){}
  
  /// memory
  /// *under construction*
  open func unload(){}
  open func load(){}
  open func memoryWarning(){}
  
  /// app handlers
  open func toBackground(){}
  open func fromBackground(){}
  open func closeApp(){}
  open func lowPower(){}
  
  open func orientationChanged() {}
  open func keyboardMoved() {}
  
  /// navigation bar
  open func willShow(){}
  open func didShow(){}
  open func willHide(){}
  open func didHide(){}
  open func closed(){}
  
  public var isCurrentPage: Bool {
    return main.currentPage == self
  }
  open var animateScreenTransitions: Bool { true }
  
  //  // private properties
  //  fileprivate var blurOverlays = [BlurOverlay]()
  weak var blurBackgroundView: UIVisualEffectView?
}

//extension SomePage {
//  public func addBlurOverlay(closeOnTap: Bool = true, tapAction: (()->())?) {
//    let view = BlurOverlay()
////    scale(from: 1.0, to: 0.9, animated: true)
////    superview?.insertSubview(view, aboveSubview: self)
//    addSubview(view)
//    view.show()
//    view.action = tapAction
//    view.closeOnTap = closeOnTap
//    blurOverlays.append(view)
//  }
//  @discardableResult
//  public func removeBlurOverlay(animated: Bool = true) -> Bool {
//    guard !blurOverlays.isEmpty else { return false }
////    scale(from: 0.9, to: 1.0, animated: animated)
//    let view = blurOverlays.removeLast()
//    view.hide(animated: animated)
//    return true
//  }
//}

extension SomePage {
  func _close() {
    closed()
    isClosed = true
  }
}
#endif
