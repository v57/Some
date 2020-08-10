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

private var c: GoBackObject!
public var NBHeight: CGFloat = 45

extension SomePage {
  public static var previous: SomePage? {
    let count = main.pages.count
    guard count > 1 else { return nil }
    let i = count-2
    return main.pages[i]
  }
  public static var first: SomePage {
    assert(!main.pages.isEmpty, "you can call SomePage.first if there is no pages")
    return main.pages.first!
  }
  public static var last: SomePage {
    assert(!main.pages.isEmpty, "you can call SomePage.last if there is no pages")
    return main.pages.last!
  }
}

open class SomeNavigationBar: DFView {
  static var main: SomeMain { SomeUI.main! }
  var main: SomeMain { SomeUI.main! }
  override public var dynamicFrame: DFrame? {
    didSet { visualEffectView.dframe = dframe }
  }
  public var effect: UIVisualEffect? {
    get { visualEffectView.effect }
    set { visualEffectView.effect = newValue }
  }
  public var visualEffectView: DFVisualEffectView
  public var titleLabel: UILabel!
  public var shows = false {
    didSet {
      if shows != oldValue {
        if shows {
          isHidden = false
          animate {
            dframe = dframeShow
          }
        } else {
          animate ({
            dframe = dframeHide
          }) {
            self.isHidden = true
          }
        }
      }
    }
  }
  
  open var dframeShow = { CGRect(0,0,screen.width,screen.top+NBHeight) }
  open var dframeHide = { CGRect(0,-(screen.top+NBHeight),screen.width,screen.top+NBHeight) }
  
  public let leftButton = DPButton2(frame: CGRect(0,screen.top,NBHeight,NBHeight), imageName: "MenuIcon")
  public let rightButton = DPButton2(frame: CGRect(screen.width - NBHeight,screen.top,NBHeight,NBHeight))
  
  private var _titleColor: UIColor = .light
  public var titleColor: UIColor {
    get {
      return _titleColor
    } set {
      _titleColor = newValue
      titleLabel.textColor = newValue
    }
  }
  open var titleFont: UIFont {
    return .normal(20)
  }
  
  private var _backIcon: UIImage?
  private func drawButton() -> UIImage {
    let lineWidth: CGFloat = 3
    let size = CGSize(12,21)
    UIGraphicsBeginImageContextWithOptions(size, false, screen.retina)
    defer { UIGraphicsEndImageContext() }
    let x: CGFloat = lineWidth/2
    let y: CGFloat = lineWidth/2
    let context = UIGraphicsGetCurrentContext()!
    
    context.setStrokeColor(titleColor.cgColor)
    context.setLineWidth(3)
    context.setLineCap(.round)
    
    context.move(to: Pos(size.width-x,y))
    context.addLine(to: Pos(x,size.height/2))
    context.addLine(to: Pos(size.width-x,size.height-y))
    context.drawPath(using: CGPathDrawingMode.stroke)
    return UIGraphicsGetImageFromCurrentImageContext()!
  }
  
  private func set(title: String?, animation: UIView.AnimationOptions?) {
    let title = title ?? ""
    if let animation = animation {
      let newFrame = titleFrame(with: title)
      let oldFrame = titleLabel.frame
      if newFrame.w >= oldFrame.w {
        titleLabel.frame = newFrame
        titleLabel.text = title
        UIView.transition(with: titleLabel, duration: 0.3, options: animation, animations: nil, completion: nil)
      } else {
        titleLabel.text = title
        UIView.transition(with: titleLabel, duration: 0.3, options: animation, animations: nil, completion: {_ in
          self.titleLabel.frame = newFrame
        })
      }
      
    } else {
      titleLabel.text = title
      titleLabel.frame = titleFrame(with: title)
    }
  }
  
  public init() {
    visualEffectView = DFVisualEffectView(effect: nil)
    
    leftButton.systemHighlighting()
    rightButton.systemHighlighting()
    
    leftButton.dpos = { Pos(0,screen.top).topLeft }
    rightButton.dpos = { Pos(screen.width,screen.top).topRight }
    
    super.init(frame: .zero)
    
    titleLabel = title(with: "")
    
    dframe = dframeHide
    visualEffectView.dframe = dframeShow
    
    isHidden = true
    
    leftButton.addTarget(self, action: #selector(SomeNavigationBar.leftButton(_:)), for: .touchUpInside)
    rightButton.addTarget(self, action: #selector(SomeNavigationBar.rightButton(_:)), for: .touchUpInside)
    addSubviews(visualEffectView,titleLabel,leftButton,rightButton)
  }
  
  @objc open func leftButton(_ sender: Any?) {
    
    if main.currentPage.leftButtonImage != nil {
      main.currentPage.leftButtonSelected()
    } else {
      if main.pages.count == 1 {
        print("Opening leftView")
      } else {
        main.back()
      }
    }
  }
  
  @objc open func rightButton(_ sender: Any?) {
    main.currentPage.rightButtonSelected()
  }
  
  open func goBackObject(_ page: SomePage, currentPage: SomePage) -> GoBackObject {
    return GoBackObject(page: page, currentPage: currentPage)
  }
  
  func goBackStart() {
    c = goBackObject(main.pages[main.pages.count - 2], currentPage: main.pages[main.pages.count - 1])
    c.start()
  }
  
  func goBack(_ value: CGFloat) {
    c.move(value)
  }
  func goBackEnd(_ x: CGFloat) {
    guard let c = c else { return }
    if x > 160 { // Go Back
      if SomeSettings.debugPages {
        print("Going back. SomePages count: \(main.pages.count-1)")
      }
      
      c.currentPage.isClosing = true
      c.currentPage.willHide()
      c.page.willShow()
      
      if let animator = c.animator {
        animator.continueAnimation!(withTimingParameters: nil, durationFactor: 0)
      } else {
        animate ({ // ne cancel
          c.endAnimation()
        }) {
          c.end()
        }
      }
    } else { // Cancel
      if let animator = c.animatorCancel {
        animator.startAnimation()
      } else {
        animate({
          c.cancelAnimation()
        }) {
          c.cancel()
        }
      }
    }
  }
  
  func goBack() {
    if SomeSettings.debugPages {
      print("Pages count: \(main.pages.count)")
    }
    guard main.pages.count > 1 else {
      if SomeSettings.debugPages {
        print("Can't go back. No more pages")
      }
      return }
    
    let page = main.pages[main.pages.count-2]
    shows = page.showsNavigationBar
    screen.statusBarWhite = page.statusBarWhite
    screen.statusBarHidden = !page.showsStatusBar
    setRightButtonImage(page.rightButtonImage)
    
    if page.showsBackButton != leftButton.shows {
      leftButton.shows = page.showsBackButton
    }
    set(title: page.title, animation: UIView.AnimationOptions.transitionFlipFromLeft)
    
    if page.leftButtonImage != nil {
      setLeftButtonImage(page.leftButtonImage)
    } else if main.pages.count == 2 {
      setLeftButtonImage(nil)
    } else if main.pages.last!.leftButtonImage != nil {
      setLeftButtonImage(backIcon)
    }
    if SomeSettings.debugPages {
      print("Going back. SomePages count: \(main.pages.count)")
    }
  }
  
  func push(_ page: SomePage) {
    shows = page.showsNavigationBar
    screen.statusBarWhite = page.statusBarWhite
    screen.statusBarHidden = !page.showsStatusBar
    let hasLeftIcon = leftButton.image(for: .normal) != nil
    setRightButtonImage(page.rightButtonImage)
    
    set(title: page.title, animation: UIView.AnimationOptions.transitionFlipFromRight)
    
    if SomeSettings.debugPages {
      print("Pushing \(className(page))")
    }
    
    if page.showsBackButton != leftButton.shows {
      if !page.showsBackButton && !hasLeftIcon {
        leftButton.alpha = 0
      } else {
        leftButton.shows = page.showsBackButton
      }
    }
    
    if page.leftButtonImage != nil {
      setLeftButtonImage(page.leftButtonImage)
    } else if main.pages.count == 1 || main.pages.last?.leftButtonImage != nil {
      setLeftButtonImage(backIcon)
    } else if main.pages.count == 0 {
      if page.leftButtonImage != nil {
        setLeftButtonImage(page.leftButtonImage)
      } else {
        setLeftButtonImage(nil)
      }
    }
    if SomeSettings.debugPages {
      print("Page count: \(main.pages.count)")
    }
  }
  
  required public init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
  override open func didMoveToSuperview() {
    if superview != nil {
      
    }
  }
  open override func resolutionChanged() {
    super.resolutionChanged()
    self.titleLabel.frame = titleFrame(with: titleLabel.text!)
    self.rightButton.frame = CGRect(screen.width - 50,screen.top,50,NBHeight)
  }
  
  open func setLeftButtonImage(_ image: UIImage!) {
    if image == nil {
      
    } else {
      //let leftButton = Button(frame: CGRect(0,20,NBHeight,NBHeight), imageName: "MenuIcon")
      //            let rightButton = Button(frame: CGRect(screen.width - NBHeight,20,NBHeight,NBHeight))
      let w = 30 + image.width
      self.leftButton.frame = CGRect(0,screen.top,w,NBHeight)
    }
    self.leftButton.setImage(image, for: UIControl.State())
  }
  
  open func setRightButtonImage(_ image: UIImage!) {
    if image == nil {
      
    } else {
      let w = 30 + image.width
      self.rightButton.frame = CGRect(screen.width - w,screen.top,w,NBHeight)
    }
    self.rightButton.setImage(image, for: UIControl.State())
  }
  open func update() {
    let page = main.pages.last!
    self.titleLabel.text = page.title
  }
  open func updateRightImage() {
    let page = main.pages.last!
    setRightButtonImage(page.rightButtonImage)
  }
}

private extension SomeNavigationBar {
  var backIcon: UIImage {
    if let backIcon = _backIcon {
      return backIcon
    } else {
      if let icon = UIImage(named: "BackIcon") {
        _backIcon = icon
        return icon
      } else {
        let icon = drawButton()
        _backIcon = icon
        return icon
      }
    }
  }
  func title(with text: String) -> UILabel {
    let label = UILabel(frame: titleFrame(with: text))
    label.textColor = titleColor
    label.font = titleFont
    label.text = text
    label.textAlignment = .center
    return label
  }
  func titleFrame(with text: String) -> CGRect {
    let maxWidth = screen.right - screen.left - 100
    
    let x = screen.left + 50 + maxWidth / 2
    let y = screen.top + NBHeight / 2
    
    var width = text.width(titleFont)
    width = min(width,maxWidth)
    let height = titleFont.lineHeight
    
    return CGRect(Pos(x,y),.center,Size(width,height))
  }
}

open class GoBackObject {
  var main: SomeMain { SomeUI.main! }
  let changeTitle: Bool
  let changeLeft: Bool
  let changeRight: Bool
  let changeTop: Bool
  let changeStatusBarColor: Bool
  let changeShowsStatusBar: Bool
  let titleLabel: Label?
  let leftButton: Button?
  let rightButton: Button?
  let page: SomePage
  let currentPage: SomePage
  var changeFrame: Bool
  var changeCurrentFrame: Bool
  var changeAlpha: Bool
  
  var animator: UIViewImplicitlyAnimating?
  var animatorCancel: UIViewImplicitlyAnimating?
  
  init(page: SomePage, currentPage: SomePage) {
    self.changeFrame = !(page.superview != nil && page.frame.x == 0 && page.frame.y == 0)
    self.changeAlpha = page.superview == nil
    self.changeCurrentFrame = true
    self.page = page
    self.currentPage = currentPage
    if page.title != "" {
      print(page.title)
      titleLabel = Label(frame: CGRect(0,screen.top,screen.width,NBHeight), text: page.title, font: .normal(20), color: _main.navigation.titleColor, alignment: NSTextAlignment.center, fixHeight: true)
      changeTitle = true
    } else {
      titleLabel = nil
      if currentPage.title != "" {
        changeTitle = true
      } else {
        changeTitle = false
      }
    }
    if page.leftButtonImage != nil {
      let w = 30 + page.leftButtonImage!.width
      leftButton = Button(frame: CGRect(0,screen.top,w,NBHeight), image: page.leftButtonImage!)
      changeLeft = true
    } else {
      leftButton = nil
      if currentPage.leftButtonImage != nil {
        changeLeft = true
      } else {
        if _main.pages.count < 3 {
          changeLeft = true
        } else {
          changeLeft = false
        }
      }
    }
    if page.rightButtonImage != nil {
      let w = 30 + page.rightButtonImage!.width
      rightButton = Button(frame: CGRect(screen.width - w,screen.top,NBHeight,NBHeight), image: page.rightButtonImage!)
      changeRight = true
    } else {
      rightButton = nil
      if currentPage.rightButtonImage != nil {
        changeRight = true
      } else {
        changeRight = false
      }
    }
    changeTop = page.showsNavigationBar != currentPage.showsNavigationBar
    changeStatusBarColor = page.statusBarWhite != currentPage.statusBarWhite
    changeShowsStatusBar = page.showsStatusBar != currentPage.showsStatusBar
  }
  open func start() {
    let nav = main.navigation
    page.alpha = 1.0
    if changeFrame {
      page.dframe = { screen.frame.offsetBy(dx: -screen.width, dy: 0) }
    } else {
      page.dframe = screen.dframe
    }
    if changeAlpha {
      main.mainView.addSubview(page)
    }
    
    titleLabel?.alpha = 0.0
    leftButton?.alpha = 0.0
    rightButton?.alpha = 0.0
    nav.addSubviews(titleLabel,leftButton,rightButton)
  }
  open func move(_ value: CGFloat) {
    if let animator = animator {
      animator.fractionComplete = value
    } else {
      let nav = main.navigation
      
      if changeFrame {
        page.frame = screen.frame.offsetBy(dx: screen.width * (value - 1), dy: 0)
      }
      currentPage.frame = screen.frame.offsetBy(dx: screen.width * value, dy: 0)
      let v = 1 - value
      if changeLeft {
        nav.leftButton.alpha = v
        leftButton?.alpha = value
      }
      if changeRight {
        nav.rightButton.alpha = v
        rightButton?.alpha = value
      }
      if changeTitle {
        //        nav.titleLabel.layer.transform = CATransform3DMakeRotation(value * .pi,1.0,1.0,0.0)
        //        titleLabel?.layer.transform = CATransform3DMakeRotation(v * .pi,1.0,0.0,0.0)
        nav.titleLabel.alpha = v
        titleLabel?.alpha = value
      }
      if changeTop {
        if page.showsNavigationBar {
          nav.frame.y = -(screen.top+NBHeight) * v
        } else {
          nav.frame.y = -(screen.top+NBHeight) * value
        }
      }
    }
  }
  open func endAnimation() {
    
    let nav = main.navigation
    
    if changeStatusBarColor {
      screen.statusBarWhite = page.statusBarWhite
    }
    if changeShowsStatusBar {
      screen.statusBarHidden = !page.showsStatusBar
    }
    if changeTop {
      nav.shows = page.showsNavigationBar
    }
    if changeFrame {
      page.dframe = screen.dframe
    }
    if changeCurrentFrame {
      currentPage.frame = screen.frame.offsetBy(dx: screen.width, dy: 0)
    }
    //    if changeTop { // удалил, потому что сверху написано тоже самое
    //      if page.showsNavigationBar {
    //        nav.frame.y = 0
    //      } else {
    //        nav.frame.y = -NBRHeight
    //      }
    //    }
    if changeLeft {
      nav.leftButton.alpha = 0
      leftButton?.alpha = 1
    }
    if changeRight {
      nav.rightButton.alpha = 0
      rightButton?.alpha = 1
    }
    if changeTitle {
      nav.titleLabel.alpha = 0
      titleLabel?.alpha = 1
    }
  }
  open func end() {
    
    let nav = main.navigation
    
    nav.setRightButtonImage(c.page.rightButtonImage)
    nav.titleLabel.frame = nav.titleFrame(with: c.page.title)
    nav.titleLabel.text = c.page.title
    
    if page.showsBackButton != nav.leftButton.shows {
      nav.leftButton.shows = page.showsBackButton
    }
    
    if page.leftButtonImage != nil {
      nav.setLeftButtonImage(c.page.leftButtonImage)
    } else if main.pages.count == 2 {
      nav.setLeftButtonImage(nil)
    } else if currentPage.leftButtonImage != nil {
      nav.setLeftButtonImage(nav.backIcon)
    }
    currentPage.removeFromSuperview()
    main.pages.removeLast()
    
    titleLabel?.removeFromSuperview()
    leftButton?.removeFromSuperview()
    rightButton?.removeFromSuperview()
    currentPage.removeFromSuperview()
    currentPage.didHide()
    currentPage._close()
    currentPage.overlay?.close()
    currentPage.overlay?.closed()
    currentPage.isClosed = true
    SomeDebug.pagesClosed += 1
    page.didShow()
    //    page.removeBlurOverlay()
    
    c = nil
    
    nav.rightButton.alpha = 1.0
    nav.titleLabel.alpha = 1.0
    nav.leftButton.alpha = 1.0
  }
  open func cancelAnimation() {
    
    let nav = main.navigation
    
    if changeFrame {
      page.frame = screen.frame.offsetBy(dx: -screen.width, dy: 0)
    }
    currentPage.dframe = screen.dframe
    
    if changeLeft {
      nav.leftButton.alpha = 1
      leftButton?.alpha = 0
    }
    if changeRight {
      nav.rightButton.alpha = 1
      rightButton?.alpha = 0
    }
    if changeTitle {
      nav.titleLabel.alpha = 1
      titleLabel?.alpha = 0
    }
    if changeTop {
      if currentPage.showsNavigationBar {
        nav.dframe = nav.dframeShow
      } else {
        nav.dframe = nav.dframeHide
      }
    }
  }
  open func cancel() {
    let nav = main.navigation
    
    titleLabel?.removeFromSuperview()
    leftButton?.removeFromSuperview()
    rightButton?.removeFromSuperview()
    if changeAlpha {
      page.removeFromSuperview()
    }
    nav.rightButton.alpha = 1.0
    nav.titleLabel.alpha = 1.0
    nav.leftButton.alpha = 1.0
    c = nil
  }
  deinit {
    animator?.stopAnimation(true)
    animatorCancel?.stopAnimation(true)
  }
}

@available(iOS 10.0, *)
open class GoBackObject2: GoBackObject {
  public override init(page: SomePage, currentPage: SomePage) {
    super.init(page: page, currentPage: currentPage)
    changeCurrentFrame = false
  }
  open override func start() {
    super.start()
    let blur = UIVisualEffectView(effect: UIBlurEffect(style: .light))
    blur.frame.h = screen.height
    let view = UIView(frame: .zero)
    view.clipsToBounds = true
    view.frame.h = screen.height
    let imageView = UIImageView(frame: screen.frame)
    imageView.image = backgroundImage
    imageView.contentMode = .scaleAspectFill
    imageView.alpha = 0.0
    view.addSubview(imageView)
    main.mainView.insertSubview(view, belowSubview: page)
    main.mainView.insertSubview(blur, belowSubview: page)
    animator = UIViewPropertyAnimator(duration: 2, curve: .linear) { [unowned self, unowned blur, unowned view] in
      UIView.animateKeyframes(withDuration: 0, delay: 0, options: [], animations: {
        UIView.addKeyframe(withRelativeStartTime: 0.25, relativeDuration: 0.5) {
          imageView.alpha = 1.0
        }
      }, completion: nil)
      blur.effect = nil
      blur.frame.w = screen.width
      view.frame.w = screen.width
      self.endAnimation()
    }
    animator!.addCompletion! { [unowned self, unowned blur, unowned view] position in
      blur.removeFromSuperview()
      view.removeFromSuperview()
      self.end()
    }
    animatorCancel = UIViewPropertyAnimator(duration: 0.3, curve: .linear) { [unowned self, unowned blur, unowned view] in
      blur.effect = UIBlurEffect(style: .light)
      blur.frame.w = 0
      view.frame.w = 0
      imageView.alpha = 0.0
      self.cancelAnimation()
    }
    animatorCancel!.addCompletion! { [unowned self, unowned blur, unowned view] position in
      blur.removeFromSuperview()
      view.removeFromSuperview()
      self.cancel()
    }
  }
}

@available(iOS 10.0, *)
open class GoBackObject3: GoBackObject {
  public override init(page: SomePage, currentPage: SomePage) {
    super.init(page: page, currentPage: currentPage)
    changeFrame = false
    changeCurrentFrame = false
  }
  open override func start() {
    super.start()
    let blur = UIVisualEffectView(effect: UIBlurEffect(style: .light))
    blur.frame.h = screen.height
    let view = UIView(frame: .zero)
    view.clipsToBounds = true
    view.frame.h = screen.height
    let imageView = UIImageView(frame: screen.frame)
    imageView.image = backgroundImage
    imageView.contentMode = .scaleAspectFill
    imageView.alpha = 0.0
    view.addSubview(imageView)
    view.addSubview(page)
    main.mainView.addSubview(view)
    main.mainView.addSubview(blur)
    //    main.mainView.insertSubview(view, belowSubview: page)
    //    main.mainView.insertSubview(blur, belowSubview: page)
    animator = UIViewPropertyAnimator(duration: 2, curve: .linear) { [unowned self, unowned blur, unowned view] in
      UIView.animateKeyframes(withDuration: 0, delay: 0, options: [], animations: {
        UIView.addKeyframe(withRelativeStartTime: 0.25, relativeDuration: 0.5) {
          imageView.alpha = 1.0
        }
      }, completion: nil)
      blur.effect = nil
      blur.frame.w = screen.width
      view.frame.w = screen.width
      self.endAnimation()
    }
    animator!.addCompletion! { [unowned self, unowned blur, unowned view] position in
      blur.removeFromSuperview()
      view.removeFromSuperview()
      _main.mainView.addSubview(self.page)
      self.end()
    }
    animatorCancel = UIViewPropertyAnimator(duration: 0.3, curve: .linear) { [unowned self, unowned blur, unowned view] in
      blur.effect = UIBlurEffect(style: .light)
      blur.frame.w = 0
      view.frame.w = 0
      imageView.alpha = 0.0
      self.cancelAnimation()
    }
    animatorCancel!.addCompletion! { [unowned self, unowned blur, unowned view] position in
      blur.removeFromSuperview()
      view.removeFromSuperview()
      self.cancel()
    }
  }
}



#endif
