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

public var backgroundImage: UIImage? = UIImage(named: "Background")

public var previousKeyboardFrame = CGRect(0,0,0,0)
public var keyboardHeight: CGFloat = 0
public func keyboardInset(for view: UIView) -> CGFloat {
  if keyboardHeight == 0 {
    return 0
  } else {
    var kheight = keyboardHeight
    kheight -= screen.height - (view.positionOnScreen.y + view.frame.h)
    return max(0,kheight)
  }
}
#if !targetEnvironment(macCatalyst)
private var screenStatusBarWhite = UIApplication.shared.statusBarStyle == .lightContent ? false : true
private var screenStatusBarHidden = UIApplication.shared.isStatusBarHidden
extension SomeScreen {
  public var statusBarWhite: Bool {
    get {
      return screenStatusBarWhite
    }
    set {
      screenStatusBarWhite = newValue
      animate {
        main?.setNeedsStatusBarAppearanceUpdate()
      }
    }
  }
  public var statusBarHidden: Bool {
    get {
      return screenStatusBarHidden
    }
    set {
      screenStatusBarHidden = newValue
      animate {
        main?.setNeedsStatusBarAppearanceUpdate()
      }
    }
  }
}
#else
extension SomeScreen {
  public var statusBarWhite: Bool {
    get { true }
    set { }
  }
  public var statusBarHidden: Bool {
    get { true }
    set { }
  }
}
#endif

open class SomeMain: UIViewController {
  public static var `default`: ()->SomeMain = { SomeMain() }
  
  public lazy var navigation = SomeNavigationBar()
  public var currentPage: SomePage {
    return pages.last!
  }
  public func find<T: SomePage>(page type: T.Type) -> T? {
    return SomeDebug.pages.allObjects.reversed().find(type)
  }
  public var pages = [SomePage]()
  public var isLoaded = false
  public var mainView = DFView()
  public var backgroundImageView: DFImageView!
  
  private var leftSwipeGesture: UIScreenEdgePanGestureRecognizer!
  private var rightSwipeGesture: UIScreenEdgePanGestureRecognizer!
  private var leftEdgeStartX: CGFloat = 0
  
  //  func setDefaultOrientation() {
  //    if UIDevice.current.orientation != UIDeviceOrientation.portrait {
  //      let value = UIInterfaceOrientation.portrait.rawValue
  //      UIDevice.current.setValue(value, forKey: "orientation")
  //    }
  //  }
  
  public var isAnimated = true
  
  public init() {
    super.init(nibName: nil, bundle: nil)
  }
  
  required public init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
  
  override open func viewDidLoad() {
    super.viewDidLoad()
    print("main: \(className(self))")
    guard !isLoaded else { return }
    DispatchQueue.main.async {
      self.viewDidLoad2()
    }
  }
  
  private func viewDidLoad2() {
    mainView.dframe = screen.dframe
    
    if #available(iOS 11.0, *) {
      
    } else {
      automaticallyAdjustsScrollViewInsets = false
    }
    
    if backgroundImage != nil {
      backgroundImageView = DFImageView()
      backgroundImageView.dframe = screen.dframe
      backgroundImageView.contentMode = UIView.ContentMode.scaleAspectFill
      backgroundImageView.clipsToBounds = true
      //      backgroundImageView.layer.cornerRadius = 40
      backgroundImageView.image = backgroundImage
      view.backgroundColor = nil
    } else {
      view.backgroundColor = .mainBackground
    }
    
    leftSwipeGesture = UIScreenEdgePanGestureRecognizer(target: self, action: #selector(SomeMain.leftEdgeSwipe))
    leftSwipeGesture.edges = .left
    view.addGestureRecognizer(leftSwipeGesture)
    
    //    rightSwipeGesture = UIScreenEdgePanGestureRecognizer(target: self, action: #selector(SomeMain.rightEdgeSwipe))
    //    rightSwipeGesture.edges = .right
    //    view.addGestureRecognizer(rightSwipeGesture)
    
    let notifications = NotificationCenter.default
    
    notifications.addObserver(self, selector: #selector(keyboardNotification(_:)), name: UIResponder.keyboardWillChangeFrameNotification, object: nil)
    notifications.addObserver(self, selector: #selector(rotate), name: UIDevice.orientationDidChangeNotification, object: nil)
    if #available(iOS 9.0, *) {
      notifications.addObserver(self, selector: #selector(checkLowPowerMode), name: .NSProcessInfoPowerStateDidChange, object: nil)
    }
    
    view.addSubview(mainView)
    view.addSubview(navigation)
    
    pages = [loadingPage]
    if backgroundImageView != nil { mainView.addSubview(backgroundImageView) }
    bottomLayer()
    mainView.addSubview(currentPage)
    topLayer()
    
    if loadingTime > 0 {
      Timer.scheduledTimer(timeInterval: loadingTime, target: self, selector: #selector(NSObject.load), userInfo: nil, repeats: false)
    } else {
      load()
    }
  }
  
  open func lowPowerModeChanged() {
    pages.forEach { $0.lowPower() }
  }
  open var loadingTime: Double {
    return 0
  }
  open var loadingPage: SomePage {
    return MainLoading()
  }
  open func bottomLayer() {
    
  }
  open func topLayer() {
    
  }
  /// Main thread
  /// update some UI before loading
  open func preloading() {
    
  }
  /// Background thread
  /// Load your data base
  open func loading() {
    
  }
  /// Main thread
  /// if db.isEmpty { shows(StartPage()) } else { shows(ProfilePage()) }
  open func loaded() {
    print("loaded")
  }
  
  /// Page transition functions
  /// empty by default
  open func shouldOpen(from: SomePage?, to: SomePage) -> Bool {
    return true
  }
  
  open func willOpen(from: SomePage, to: SomePage) {
    
  }
  
  open func willClose(from: SomePage, to: SomePage) {
    
  }
  
  private func load() {
    preloading()
    backgroundThread {
      self.loading()
      mainThread {
        self.isLoaded = true
        if let test = SomePage.test() {
          self.show(test)
        } else {
          self.loaded()
        }
        app.notifications.loaded()
      }
    }
  }
  
  public func lock(_ execute: ()->()) {
    isAnimated = false
    execute()
    isAnimated = true
  }
  
  public func push(_ page: SomePage?) {
    guard let page = page else { return }
    
    let transition = page.transition
    transition.push(left: currentPage, right: page, animated: isAnimated)
  }
  public var previousPage: SomePage? {
    return pages.right(1)
  }
  public func back() {
    let transition = currentPage.transition
    transition.right = currentPage
    transition.left = pages.right(1)
    transition.back(animated: isAnimated)
  }
  public func show(_ page: SomePage?) {
    guard let page = page else { return }
    let last = pages.last
    let closedPages = pages
    pages.removeAll()
    
    let transition = PageTransition.fade
    transition.push(left: last, right: page, animated: isAnimated)
    for page in closedPages {
      page._close()
    }
  }
  public func replace(last count: Int, with page: SomePage?) {
    guard let page = page else { return }
    let closed = pages.last(count)
    pages.removeLast(count)
    //    pages.removeAll()
    
    let transition = page.transition
    transition.push(left: closed.last, right: page, animated: isAnimated)
    for page in closed {
      page.removeFromSuperview()
      page.overlay?.close()
      page.overlay?.closed()
      page._close()
    }
  }
  
  open func close(_ page: SomePage) {
    guard let index = pages.firstIndex(of: page) else { return }
    if page == currentPage {
      back()
    } else {
      page.closed()
      page.isClosed = true
      pages.remove(at: index)
    }
  }
  
  override open func didReceiveMemoryWarning() {
    super.didReceiveMemoryWarning()
    pages.forEach { $0.memoryWarning() }
    // Dispose of any resources that can be recreated.
  }
  override open var preferredStatusBarStyle : UIStatusBarStyle {
    return screen.statusBarWhite ? .lightContent : .default
  }
  open override var preferredStatusBarUpdateAnimation : UIStatusBarAnimation {
    return UIStatusBarAnimation.slide
  }
  override open var prefersStatusBarHidden : Bool {
    return screen.statusBarHidden
  }
  open override var supportedInterfaceOrientations: UIInterfaceOrientationMask { screen.orientations }
  open func keyboardMoved() {
    let seq = mainView.subviews.reversed()
    for subview in seq {
      guard let page = subview as? SomePage else { continue }
      page.keyboardMoved()
      return
    }
    currentPage.keyboardMoved()
  }
  
  open func resolutionChanged() {
    _resolutionChanged()
  }
  
  override open func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
    _viewWillTransition(to: size, with: coordinator)
    super.viewWillTransition(to: size, with: coordinator)
  }
}

private extension SomeMain {
  @objc func keyboardNotification(_ sender: Notification) {
    if let userInfo = (sender as NSNotification).userInfo {
      if previousKeyboardFrame.y == 0 {
        let fs = (userInfo[UIResponder.keyboardFrameBeginUserInfoKey] as? NSValue)!.cgRectValue
        previousKeyboardFrame = fs
      }
      let frameEnd = (userInfo[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)!.cgRectValue
      keyboardHeight = screen.height - frameEnd.y
      let duration = (userInfo[UIResponder.keyboardAnimationDurationUserInfoKey]! as AnyObject).doubleValue!
      animateKeyboard(duration) {
        let c = isAnimating
        isAnimating = true
        self.keyboardMoved()
        isAnimating = c
      }
      previousKeyboardFrame = frameEnd
    }
  }
  @objc func checkLowPowerMode() {
    let changed = Device.updateLowPowerMode()
    if changed {
      lowPowerModeChanged()
    }
  }
  
  @objc func leftEdgeSwipe(_ gesture: UIScreenEdgePanGestureRecognizer) {
    guard pages.count > 1 else {
      gesture.cancel()
      return
    }
    guard let page = pages.last else { return }
    guard page.isFullscreen else {
      gesture.cancel()
      return
    }
    page.transition.leftSwipe(gesture: gesture)
  }
  
  @objc func rightEdgeSwipe(_ gesture: UIScreenEdgePanGestureRecognizer) {
    guard pages.count > 1 else {
      gesture.cancel()
      return
    }
    guard let page = pages.last else { return }
    guard page.isFullscreen else {
      gesture.cancel()
      return
    }
    page.transition.rightSwipe(gesture: gesture)
  }
  
  @objc func rotate() {
    currentPage.orientationChanged()
  }
  
}

private func statusBarAnimation(_ animation: @escaping ()->()) {
  UIView.animate(withDuration: 0.35, animations: animation)
}
#endif
