
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

public let svo: CGFloat = 30
public let svo2 = svo/2
public let distansion: CGFloat = 70

public enum LoadingError {
  case unknown, lostConnection
}

open class ScrollViewSnapshot {
  open var topLoading = false
  open var bottomLoading = false
  open var loadMoreTopLoading = false
  open var loadMoreBottomLoading = false
  open var firstLoad = false
  open var contentSize = CGSize()
  open var contentInset = UIEdgeInsets.zero
  open var loadingIndicatorShow = false
  open var loadingIndicatorPosition = CGPoint()
  open var topLoadingIndicatorShow = false
  open var topLoadingIndicatorPosition = CGPoint()
  
  open var topLoadingChanged = false
  open var bottomLoadingChanged = false
  open var loadMoreTopLoadingChanged = false
  open var loadMoreBottomLoadingChanged = false
  open var firstLoadChanged = false
  
  open var settings = ScrollViewSettings()
}

open class ScrollViewTopBottom {
  final public var top = false
  final public var bottom = false
}

open class ScrollViewSettings {
  final public let autoload = ScrollViewTopBottom()
  final public let pullToRefresh = ScrollViewTopBottom()
  final public var firstLoad = false // изменять нужно перед addSubview
  final public var topOffset: CGFloat = 0 // изменять нужно перед addSubview
}

open class ScrollView: UIScrollView2, UIScrollViewDelegate {
  final public weak var  scrollViewDelegate: ScrollViewDelegate?
  
  final private lazy var loadingIndicator = LoadingViewDefault(center: CGPoint(), color: .black)
  final private lazy var topLoadingIndicator = LoadingViewDefault(center: CGPoint(), color: .black)
  final private lazy var bottomLoadingIndicator = LoadingViewDefault(center: CGPoint(screen.center.x,screen.height), color: .black)
  
  final public var topLoading = false {
    didSet {
      if oldValue != topLoading && setterTrigger {
        if topLoading {
          noDelegate {
            contentInset.top += svo
          }
          topLoadingIndicator.animating = true
          scrollViewDelegate?.pullToRefreshTop?(self)
        } else {
          if contentOffset.y + contentInset.top > 0 {
            noDelegate {
              contentInset.top -= svo
            }
          } else {
            var inset = contentInset
            inset.top -= svo
            animate {
              self.contentInset = inset
            }
          }
          topLoadingIndicator.shows = false
        }
      }
    }
  }
  final public var bottomLoading = false {
    didSet {
      if oldValue != bottomLoading && setterTrigger {
        if bottomLoading {
          noDelegate {
            contentInset.bottom += svo
          }
          bottomLoadingIndicator.animating = true
          scrollViewDelegate?.pullToRefreshBottom?(self)
        } else {
          if contentOffset.y + frame.h - contentSize.height < -svo {
            noDelegate {
              contentInset.bottom -= svo
            }
          } else {
            var i = self.contentInset
            i.bottom -= svo
            animate {
              self.contentInset = i
            }
          }
          bottomLoadingIndicator.shows = false
        }
      }
    }
  }
  final public var loadMoreTopLoading = false
  final public var loadMoreBottomLoading = false {
    didSet {
      if oldValue != loadMoreBottomLoading && setterTrigger {
        if loadMoreBottomLoading {
          noDelegate {
            contentInset.bottom += svo
          }
          bottomLoadingIndicator.center = CGPoint(x: self.frame.w/2, y: contentSize.height - svo2)
          bottomLoadingIndicator.shows = true
          bottomLoadingIndicator.animating = true
          scrollViewDelegate?.loadMoreBottom?(self)
        } else {
          if contentOffset.y + frame.h - contentSize.height < -svo {
            noDelegate {
              contentInset.bottom -= svo
            }
          } else {
            animate {
              noDelegate {
                self.contentInset.bottom -= svo
              }
            }
          }
          bottomLoadingIndicator.shows = false
        }
      }
    }
  }
  
  final public var firstLoad = true {
    didSet {
      if oldValue != firstLoad && setterTrigger {
        if self.firstLoad {
          loadingIndicator.shows = true
          loadingIndicator.animating = true
          scrollViewDelegate?.firstLoad?(self)
        } else {
          loadingIndicator.shows = false
        }
      }
    }
  }
  
  final public let settings = ScrollViewSettings()
  
  final private var maskCreated = false
  
  final private var setterTrigger = true
  
  // MARK:- Init
  override public init(frame: CGRect) {
    super.init(frame: frame)
    afterInit()
    alwaysBounceVertical = true
  }
  required public init?(coder aDecoder: NSCoder) {
    super.init(coder: aDecoder)
    afterInit()
  }
  
  private func afterInit() {
    delegate = self
  }
  
  final override public func didMoveToSuperview() {
    super.didMoveToSuperview()
    if superview != nil {
      if settings.pullToRefresh.top || settings.pullToRefresh.bottom || settings.autoload.top || settings.autoload.bottom || settings.firstLoad {
        if settings.pullToRefresh.top || settings.autoload.top {
          topLoadingIndicator.shows = false
          addSubview(topLoadingIndicator)
        }
        if settings.pullToRefresh.bottom || settings.autoload.bottom {
          bottomLoadingIndicator.shows = false
          addSubview(bottomLoadingIndicator)
        }
        if settings.firstLoad {
          addSubview(loadingIndicator)
        }
        loadingIndicator.center = CGPoint(x: bounds.w/2, y: bounds.h/2)
        if settings.firstLoad {
          loadingIndicator.animating = true
          scrollViewDelegate?.firstLoad?(self)
        } else {
          loadingIndicator.shows = false
        }
      }
      if settings.topOffset != 0 {
        noDelegate {
          contentInset.top += settings.topOffset
        }
      }
    }
  }
  
  
  // MARK:- UIScrollView2 delegate
  final public func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
    if settings.pullToRefresh.top && !topLoading {
      if !topLoadingIndicator.animating {
        if contentOffset.y + contentInset.top < -distansion {
          topLoading = true
        } else {
          topLoadingIndicator.shows = false
        }
      }
    }
    if settings.pullToRefresh.bottom && !bottomLoading {
      if !bottomLoadingIndicator.animating {
        if contentOffset.y + frame.h - contentSize.height > distansion {
          bottomLoading = true
        } else {
          bottomLoadingIndicator.shows = false
        }
      }
    }
    if (!decelerate) {
      stoppedScrolling();
    }
  }
  
  open func scrollViewDidScroll(_ scrollView: UIScrollView) {
    if settings.pullToRefresh.top {
      let y = contentOffset.y + contentInset.top
      if y < 0 {
        if !topLoading {
          topLoadingIndicator.center = CGPoint(x: center.x + contentOffset.x, y: y / 2)
          topLoadingIndicator.value = -y / distansion
          if !isDecelerating {topLoadingIndicator.shows = true}
        } else {
          topLoadingIndicator.center = CGPoint(x: center.x + contentOffset.x, y: (y-svo) / 2)
        }
      }
    }
    if settings.pullToRefresh.bottom {
      let y = contentOffset.y + frame.h - contentSize.height
      if y > 0 {
        bottomLoadingIndicator.center = CGPoint(x: center.x + contentOffset.x, y: contentSize.height + y / 2)
        if !bottomLoading {
          bottomLoadingIndicator.value = y / distansion
          bottomLoadingIndicator.shows = true
        }
      }
    }
    
    if maskCreated {
      CATransaction.begin()
      CATransaction.setDisableActions(true)
      layer.mask!.frame = CGRect(bounds.x, bounds.y,bounds.w, bounds.h)
      CATransaction.commit()
    }
    
    if settings.autoload.bottom && !loadMoreBottomLoading {
      if contentOffset.y > contentSize.height - self.frame.h * 2 {
        loadMoreBottomLoading = true
      }
    }
    if hideOnScroll {
      offsetY = contentOffset.y - previousY
      let bottom = contentOffset.y + frame.h
      let dist = contentSize.height - bottom
      let top = contentOffset.y + contentInset.top
      if offsetY > 0 {
        if top <= 0 {
          currentY = 0
        } else {
          currentY = min(currentY + offsetY, min(dist, maxY))
          currentY = max(currentY, 0)
          currentY = min(currentY, maxY)
        }
      } else {
        if dist < 0 {
          currentY = 0
        } else {
          currentY = min(currentY + offsetY, min(top, maxY))
          currentY = max(currentY, 0)
          currentY = min(currentY, maxY)
        }
      }
      self.scrollViewDelegate?.hideOnScroll?(self.currentY, max: self.maxY, animated: true)
    }
    previousY = contentOffset.y
    scrollViewDelegate?.didScroll?(self)
  }
  
  final public func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
    stoppedScrolling()
  }
  
  open func stoppedScrolling() {
    if hideOnScroll {
      let canMax = contentOffset.y > maxY
      if currentY > maxY / 2 && canMax {
        currentY = maxY
      } else {
        currentY = 0
      }
      animate {
        self.scrollViewDelegate?.hideOnScroll?(self.currentY, max: self.maxY, animated: true)
      }
    }
  }
  
  final public func createPullToRefreshTop() {
    settings.pullToRefresh.top = true
  }
  
  final public func createPullToRefreshBottom() {
    settings.pullToRefresh.bottom = true
  }
  
  final public func createAutoloadTop() {
    settings.autoload.top = true
  }
  
  final public func createAutoloadBottom() {
    settings.autoload.bottom = true
  }
  
  final public func createMask(_ vertical: Bool = true) {
    if !maskCreated {
      maskCreated = true
      showsVerticalScrollIndicator = false
      let maskPower: Float = 15 / Float(vertical ? frame.h : frame.w)
      let transparent = UIColor(white: 0, alpha: 1).cgColor
      let opaque = UIColor(white: 0, alpha: 0).cgColor
      let mask = CAGradientLayer()
      mask.colors = NSArray(array: [opaque,transparent, transparent, opaque]) as [AnyObject]
      mask.locations = [NSNumber(value: 0.0 as Float), NSNumber(value: maskPower as Float), NSNumber(value: 1 - maskPower as Float), NSNumber(value: 1.0 as Float)]
      if vertical {
        mask.startPoint = CGPoint(x: 0.5,y: 0.0)
        mask.endPoint   = CGPoint(x: 0.5,y: 1.0)
      } else {
        mask.startPoint = CGPoint(x: 0.0,y: 0.5)
        mask.endPoint   = CGPoint(x: 1.0,y: 0.5)
      }
      mask.bounds = bounds
      mask.anchorPoint = CGPoint.zero
      layer.mask = mask
    }
  }
  
  final public func makeSnapshot() -> ScrollViewSnapshot {
    print("BottomLoading \(loadMoreBottomLoading) settings \(settings.autoload.bottom)")
    let snapshot = ScrollViewSnapshot()
    snapshot.topLoading = topLoading
    snapshot.bottomLoading = bottomLoading
    snapshot.loadMoreTopLoading = loadMoreTopLoading
    snapshot.loadMoreBottomLoading = loadMoreBottomLoading
    snapshot.firstLoad = firstLoad
    snapshot.contentSize = contentSize
    snapshot.contentInset = contentInset
    snapshot.loadingIndicatorShow = loadingIndicator.shows
    snapshot.loadingIndicatorPosition = loadingIndicator.center
    
    snapshot.settings.autoload.top = settings.autoload.top
    snapshot.settings.autoload.bottom = settings.autoload.bottom
    snapshot.settings.pullToRefresh.top = settings.pullToRefresh.top
    snapshot.settings.pullToRefresh.bottom = settings.pullToRefresh.bottom
    snapshot.settings.firstLoad = settings.firstLoad // читай описание
    snapshot.settings.topOffset = settings.topOffset // читай описание
    
    return snapshot
  }
  
  final public func restoreSnapshot(_ snapshot: ScrollViewSnapshot?) {
    if snapshot != nil {
      
      print("Scrollview BottomLoading \(loadMoreBottomLoading) settings \(settings.autoload.bottom)")
      print("Snapshot   BottomLoading \(snapshot!.loadMoreBottomLoading) settings \(snapshot!.settings.autoload.bottom) changed \(snapshot!.loadMoreBottomLoadingChanged)")
      
      settings.autoload.top = snapshot!.settings.autoload.top
      settings.autoload.bottom = snapshot!.settings.autoload.bottom
      settings.pullToRefresh.top = snapshot!.settings.pullToRefresh.top
      settings.pullToRefresh.bottom = snapshot!.settings.pullToRefresh.bottom
      settings.firstLoad = snapshot!.settings.firstLoad // читай описание
      settings.topOffset = snapshot!.settings.topOffset // читай описание
      
      topLoading = snapshot!.topLoading
      bottomLoading = snapshot!.bottomLoading
      loadMoreTopLoading = snapshot!.loadMoreTopLoading
      loadMoreBottomLoading = snapshot!.loadMoreBottomLoading
      
      firstLoad = snapshot!.firstLoad
      loadingIndicator.shows = snapshot!.loadingIndicatorShow
      loadingIndicator.center = snapshot!.loadingIndicatorPosition
      self.delegate = nil
      contentSize = snapshot!.contentSize
      contentInset = snapshot!.contentInset
      self.delegate = self
      
      if snapshot!.topLoadingChanged {topLoading = !topLoading}
      if snapshot!.bottomLoadingChanged {bottomLoading = !bottomLoading}
      if snapshot!.loadMoreTopLoadingChanged {loadMoreTopLoading = !loadMoreTopLoading}
      if snapshot!.loadMoreBottomLoadingChanged {loadMoreBottomLoading = !loadMoreBottomLoading}
      if snapshot!.firstLoadChanged {firstLoad = !firstLoad}
    }
  }
  open var shows: Bool = true {
    didSet {
      if oldValue != self.shows {
        if self.shows {
          if self.superview == nil {
            self.alpha = 1.0
          } else {
            animate {self.alpha = 1.0}
          }
        } else {
          if self.superview == nil {
            self.alpha = 0.0
          } else {
            animate {self.alpha = 0.0}
          }
        }
      }
    }
  }
  
  // MARK:- Hide on scroll
  private var hideOnScroll = false
  private var maxY: CGFloat = 0
  private var currentY: CGFloat = 0
  private var previousY: CGFloat = 0
  private var offsetY: CGFloat = 0
  
  open func hideOnScroll(_ maxY: CGFloat) {
    hideOnScroll = true
    self.maxY = maxY
  }
  open func hideOnScrollReset() {
    currentY = 0
    animate {
      self.scrollViewDelegate?.hideOnScroll?(self.currentY, max: self.maxY, animated: true)
    }
  }
  
}

// MARK:- Protocol

@objc public protocol ScrollViewDelegate: NSObjectProtocol {
  @objc optional func pullToRefreshTop(_ scrollView: ScrollView)
  @objc optional func pullToRefreshBottom(_ scrollView: ScrollView)
  @objc optional func loadMoreTop(_ scrollView: ScrollView)
  @objc optional func loadMoreBottom(_ scrollView: ScrollView)
  @objc optional func firstLoad(_ scrollView: ScrollView)
  @objc optional func navigationBarMoving(_ scrollView: ScrollView, y: CGFloat)
  @objc optional func navigationBarMoved(_ scrollView: ScrollView, y: CGFloat)
  @objc optional func didScroll(_ scrollView: ScrollView)
  @objc optional func hideOnScroll(_ y: CGFloat, max: CGFloat, animated: Bool)
}


private extension UIScrollView {
  func noDelegate(block: ()->()) {
    let d = delegate
    let co = contentOffset
    delegate = nil
    defer {
      delegate = d
      contentOffset = co
    }
    block()
  }
}
