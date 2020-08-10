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
import Some

// MARK:- #Label

open class Label: UILabel {
  open var shows: Bool = true {
    didSet {
      if oldValue != self.shows {
        if self.shows {
          if self.superview == nil {
            self.alpha = 1.0
            self.isHidden = false
          } else {
            self.isHidden = false
            UIView.animate(withDuration: 0.3, animations: {self.alpha = 1.0})
          }
        } else {
          if self.superview == nil {
            self.alpha = 0.0
            self.isHidden = true
          } else {
            UIView.animate(withDuration: 0.3, animations: {self.alpha = 0.0}, completion: { (completed) -> Void in
              if completed {
                self.isHidden = true
              }
            })
          }
        }
      }
    }
  }
  open func highlightText() {
    if let text = text {
      var tracing = false
      var length = 0
      var start = 0
      var word = ""
      
      let at = MString(string: text)
      
      for (i, c) in text.enumerated() {
        let cs = c == " "
        let ch = c == "#"
        let cm = c == "@"
        if tracing {
          if cs || ch || cm {
            if length > 1 {
              let range = NSMakeRange(start+1, length-1)
              let symbolRange = NSMakeRange(start, 1)
              at.addAttribute(AString.Key.foregroundColor, value: UIColor.hashtag, range: range)
              at.addAttribute(AString.Key.foregroundColor, value: UIColor.hashtagSymbol, range: symbolRange)
            }
            if ch || cm {
              word = String(c)
              start = i
              length = 1
            } else {
              tracing = false
            }
          }
          else {
            length += 1
            word.append(c)
          }
        } else {
          if ch || cm {
            tracing = true
            start = i
            length = 1
            word = String(c)
          }
        }
      }
      if tracing {
        if length > 1 {
          let symbolRange = NSMakeRange(start, 1)
          at.addAttribute(AString.Key.foregroundColor, value: UIColor.hashtagSymbol, range: symbolRange)
          let range = NSMakeRange(start+1, length-1)
          at.addAttribute(AString.Key.foregroundColor, value: UIColor.hashtag, range: range)
        }
      }
      attributedText = at
    }
  }
}

open class LoadingLabel: Label {
  private var timer = false
  private var loadingText: String!
  private var loadingTickCount: UInt8 = 0
  open var loading = false {
    didSet {
      if loading != oldValue {
        if loading {
          loadingText = text
          self.loadingTickCount = 0
          if !timer {
            wait(0.5) {
              self.loadingTick()
            }
          }
        } else {
          self.text = self.loadingText
        }
      }
    }
  }
  open func loadingTick() {
    if loading {
      loadingTickCount += 1
      if loadingTickCount == 4 {
        loadingTickCount = 1
      }
      switch loadingTickCount {
      case 1: text = loadingText + "."
      case 2: text = loadingText + ".."
      case 3: text = loadingText + "..."
      default: break
      }
      wait(0.5) {
        self.loadingTick()
      }
    } else {
      timer = false
    }
  }
}
#endif
