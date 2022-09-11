#if canImport(UIKit)
//
//  File.swift
//
//
//  Created by Dmitry Kozlov on 21/01/2021.
//

import UIKit

public extension UIView {
  func contextMenu() -> ContextMenu? {
    guard #available(iOS 13.0, *) else { return nil }
    if let menu = interactions.firstMap(as: ContextMenuInteraction.self) {
      return menu.controller
    } else {
      let menu = ContextMenuInteraction(0)
      addInteraction(menu)
      return menu.controller
    }
  }
}

protocol ContextMenuProtocol: class {
  var title: String { get set }
  @available(iOS 13.0, *)
  var items: [UIMenuElement] { get set }
}

public struct SystemIcon: ExpressibleByStringLiteral {
  public var rawValue: String
  public init(rawValue: String) {
    self.rawValue = rawValue
  }
  public init(stringLiteral value: String) {
    self.rawValue = value
  }
}
public extension SystemIcon {
  static var copy: SystemIcon = "doc.on.doc"
}

public struct ContextMenu {
  unowned var parent: ContextMenuProtocol
  public func title(_ string: String) -> ContextMenu {
    parent.title = string
    return self
  }
  public enum State: Int {
    case off, on, mixed
  }
  public enum Attributes: UInt8 {
    case disabled, destructive, hidden
  }
  @discardableResult
  public func menu(_ title: String, _ image: SystemIcon?, _ attributes: Attributes.Set = 0, state: State = .off, action: @escaping ()->()) -> ContextMenu {
    guard #available(iOS 13.0, *) else { return self }
    guard !parent.items.contains(where: { $0.title == title }) else { return self }
    
    var _attributes: UIMenuElement.Attributes = []
    attributes.forEach {
      switch $0 {
      case .disabled: _attributes.insert(.disabled)
      case .destructive: _attributes.insert(.destructive)
      case .hidden: _attributes.insert(.hidden)
      }
    }
    var _state = UIMenuElement.State.off
    switch state {
    case .mixed: _state = .mixed
    case .off: _state = .off
    case .on: _state = .on
    }
    let _image: UIImage?
    if let image = image {
      _image = UIImage(systemName: image.rawValue)
    } else {
      _image = nil
    }
    
    let action = UIAction(title: title, image: _image, identifier: nil, discoverabilityTitle: nil, attributes: _attributes, state: _state) { _ in
      action()
    }
    parent.items.append(action)
    return self
  }
}

@available(iOS 13.0, *)
class ContextMenuInteraction: UIContextMenuInteraction, ContextMenuProtocol {
  var title: String = ""
  let _delegate = Delegate()
  var controller: ContextMenu { ContextMenu(parent: self) }
  var items = [UIMenuElement]()
  init(_ v: Int) {
    super.init(delegate: _delegate)
    _delegate.parent = self
  }
  class Delegate: NSObject, UIContextMenuInteractionDelegate {
    weak var parent: ContextMenuInteraction?
    func contextMenuInteraction(_ interaction: UIContextMenuInteraction, configurationForMenuAtLocation location: CGPoint) -> UIContextMenuConfiguration? {
      UIContextMenuConfiguration(identifier: nil, previewProvider: nil) { [unowned self] (actions) -> UIMenu? in
        guard let parent = self.parent else { return nil }
        return UIMenu(title: parent.title, image: nil, identifier: nil, options: .displayInline, children: parent.items)
        
      }
    }
  }
}
#endif
