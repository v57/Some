#if canImport(UIKit)
//
//  File.swift
//
//
//  Created by Dmitry Kozlov on 21/01/2021.
//

import UIKit

//public extension UIView {
//  func contextMenu() -> ContextMenu? {
//    if let menu = interactions.firstMap(as: ContextMenuInteraction.self) {
//      return menu.controller
//    } else {
//      let menu = ContextMenuInteraction()
//      addInteraction(menu)
//      return menu.controller
//    }
//  }
//  func removeContextMenu() {
//    guard #available(iOS 13.0, *) else { return }
//    if let interaction = interactions.first(where: { $0 is UIContextMenuInteraction }) {
//      removeInteraction(interaction)
//    }
//  }
//}

protocol ContextMenuProtocol: AnyObject {
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
  public var image: UIImage? {
    if #available(iOS 13.0, *) {
      return UIImage(systemName: rawValue)
    } else {
      return nil
    }
  }
}
public extension SystemIcon {
  static var copy: SystemIcon = "doc.on.doc"
  static var reply: SystemIcon = "arrowshape.turn.up.left.fill"
  static var delete: SystemIcon = "trash"
  static var edit: SystemIcon = "square.and.pencil"
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
    case destructive
  }
  @discardableResult
  @available(iOS 13.0, *)
  public func menu(action: UIMenuElement) -> ContextMenu {
    guard !parent.items.contains(where: { $0.title == action.title }) else { return self }
    parent.items.append(action)
    return self
  }
  @discardableResult
  public func _menu(_ title: String, _ image: UIImage?, _ attributes: Attributes.Set = 0, state: State = .off, action: @escaping ()->()) -> ContextMenu {
    guard #available(iOS 13.0, *) else { return self }
    guard !parent.items.contains(where: { $0.title == title }) else { return self }
    
    var _attributes: UIMenuElement.Attributes = []
    attributes.forEach {
      switch $0 {
      case .destructive: _attributes.insert(.destructive)
      }
    }
    var _state = UIMenuElement.State.off
    switch state {
    case .mixed: _state = .mixed
    case .off: _state = .off
    case .on: _state = .on
    }
    let action = UIAction(title: title, image: image, identifier: nil, discoverabilityTitle: nil, attributes: _attributes, state: _state) { _ in
      action()
    }
    parent.items.append(action)
    return self
  }
  @discardableResult
  public func _menu(_ title: String, _ image: SystemIcon?, _ attributes: Attributes.Set = 0, state: State = .off, action: @escaping ()->()) -> ContextMenu {
    var _image: UIImage?
    if let image = image {
      if #available(iOS 13.0, *) {
        _image = UIImage(systemName: image.rawValue)
      }
    }
    return _menu(title, _image, attributes, state: state, action: action)
  }
  @available(iOS 13.0, *)
  public var lastAction: UIAction? {
    parent.items.last as? UIAction
  }
}

@available(iOS 13.0, *)
class ContextMenuInteraction: UIContextMenuInteraction, ContextMenuProtocol {
  var title: String = ""
  let _delegate = Delegate()
  var controller: ContextMenu { ContextMenu(parent: self) }
  var items = [UIMenuElement]()
  init() {
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
    func contextMenuInteraction(_ interaction: UIContextMenuInteraction, previewForHighlightingMenuWithConfiguration configuration: UIContextMenuConfiguration) -> UITargetedPreview? {
      guard let parent = parent else { return nil }
      guard let view = parent.view else { return nil }
      guard let superview = view.superview else { return nil }
      let target = UIPreviewTarget(container: superview, center: view.center)
      let parameters = UIPreviewParameters()
      parameters.backgroundColor = .clear
      return UITargetedPreview(view: view, parameters: parameters, target: target)
    }
  }
}
#endif
