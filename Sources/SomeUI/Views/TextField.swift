
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

// MARK:- #Textfield
open class TextField: UITextField, UITextFieldDelegate {
  open var completed = false
  private var dateMode = false
  
  let settings = Settings()
  
  open var image: UIImage? {
    didSet {
      if image != nil {
        let iv = UIImageView(frame: leftView != nil ? leftView!.frame : CGRect(0,0,30,frame.h))
        iv.image = image
        iv.contentMode = UIView.ContentMode.center
        leftView = iv
      }
    }
  }
  public init(frame: CGRect, placeholder: String?, font: UIFont, color: UIColor, clearsOnSelect: Bool, returnKey: UIReturnKeyType, leftOffset: CGFloat) {
    super.init(frame: frame)
    if placeholder != nil {
      self.attributedPlaceholder = AString(string: placeholder!, attributes: [AString.Key.foregroundColor : UIColor.placeholder])
    }
    self.font = font
    self.textColor = color
    self.clearsOnBeginEditing = clearsOnSelect
    self.returnKeyType = returnKey
    if leftOffset != 0 {
      leftView = UIView(frame: CGRect(0,0,leftOffset,frame.h))
      leftViewMode = .always
    }
  }
  
  public convenience init(size: CGSize, placeholder: String?, font: UIFont, color: UIColor, clearsOnSelect: Bool, returnKey: UIReturnKeyType, leftOffset: CGFloat) {
    self.init(frame: CGRect(origin: .zero, size: size), placeholder: placeholder, font: font, color: color, clearsOnSelect: clearsOnSelect, returnKey: returnKey, leftOffset: leftOffset)
  }
  public convenience init(placeholder: String?, font: UIFont, color: UIColor, clearsOnSelect: Bool, returnKey: UIReturnKeyType, leftOffset: CGFloat) {
    self.init(frame: .zero, placeholder: placeholder, font: font, color: color, clearsOnSelect: clearsOnSelect, returnKey: returnKey, leftOffset: leftOffset)
  }
  
  required public init?(coder aDecoder: NSCoder) {
    super.init(coder: aDecoder)
  }
  
  open func setDateMode() {
    delegate = self
    keyboardType = UIKeyboardType.numberPad
    dateMode = true
  }
  
  open func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
    if dateMode {
      let backspace = strcmp(string.cString(using: String.Encoding.utf8)!, "\\b") == -92
      let oldCount = text!.count
      if backspace {
        completed = false
        if oldCount == 5 || oldCount == 8 {
          text = text!.removeLast(1)
          return false
        }
        return true
      } else {
        if oldCount == 3 || oldCount == 6 {
          text = text! + string + "-"
          return false
        } else if oldCount == 9 {
          completed = true
          return true
        } else if oldCount == 10 {
          return false
        }
      }
    }
    return true
  }
  override open func canPerformAction(_ action: Selector, withSender sender: Any?) -> Bool {
    var option: TextFieldAction!
    switch action {
    case #selector(cut):
      option = .cut
    case #selector(UIResponderStandardEditActions.copy):
      option = .copy
    case #selector(select):
      option = .select
    case #selector(selectAll):
      option = .selectAll
    case #selector(delete):
      option = .delete
    case #selector(makeTextWritingDirectionLeftToRight):
      option = .makeTextWritingDirectionLeftToRight
    case #selector(makeTextWritingDirectionRightToLeft):
      option = .makeTextWritingDirectionRightToLeft
    case #selector(toggleBoldface):
      option = .toggleBoldface
    case #selector(toggleItalics):
      option = .toggleItalics
    case #selector(toggleUnderline):
      option = .toggleUnderline
    case #selector(increaseSize):
      option = .increaseSize
    case #selector(decreaseSize):
      option = .decreaseSize
    default:
      return super.canPerformAction(action, withSender: sender)
    }
    if settings.contains(option) {
      return settings[option]
    } else {
      return super.canPerformAction(action, withSender: sender)
    }
  }
  override open func closestPosition(to point: CGPoint) -> UITextPosition? {
    return self.position(from: self.beginningOfDocument, offset: text!.count)
  }
  enum TextFieldAction: UInt8 {
    case cut, copy, paste, select, selectAll, delete, makeTextWritingDirectionLeftToRight, makeTextWritingDirectionRightToLeft, toggleBoldface, toggleItalics, toggleUnderline, increaseSize, decreaseSize
  }
  struct Settings {
    var changed = 0
    var options = 0
    func contains(_ option: TextFieldAction) -> Bool {
      return changed[option.rawValue]
    }
    subscript(option: TextFieldAction) -> Bool {
      get {
        return options[option.rawValue]
      } set {
        options[option.rawValue] = newValue
        changed[option.rawValue] = true
      }
    }
  }
}
