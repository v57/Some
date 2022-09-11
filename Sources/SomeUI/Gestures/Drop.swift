//
//  File.swift
//  
//
//  Created by Dmitry Kozlov on 13.05.2021.
//
#if canImport(UIKit)
import Some
import UIKit

public extension UIView {
  @discardableResult
  func fileDrop(_ urls: @escaping ([FileURL])->()) -> FileDrop {
    let interaction = FileDropInteraction()
    interaction.received.forEach(urls).store(in: interaction)
    addInteraction(interaction)
    return FileDrop(interaction: interaction, bag: interaction)
  }
}

class FileDropInteraction: UIDropInteraction, PipeStorage {
  var enter = P<UIDropSession>()
  var leave = P<UIDropSession>()
  var end = P<UIDropSession>()
  var received = P<[FileURL]>()
  let _delegate = Delegate()
  var pipes: Set<C> = []
  
  init() {
    super.init(delegate: _delegate)
    _delegate.parent = self
  }
  class Delegate: NSObject, UIDropInteractionDelegate {
    weak var parent: FileDropInteraction?
    func dropInteraction(_ interaction: UIDropInteraction, canHandle session: UIDropSession) -> Bool {
      return true
//      return session.containsUrl()
    }
    
    func dropInteraction(_ interaction: UIDropInteraction, sessionDidUpdate session: UIDropSession) -> UIDropProposal {
      return UIDropProposal(operation: .copy)
    }
    
    func dropInteraction(_ interaction: UIDropInteraction, performDrop session: UIDropSession) {
      session.loadFileUrls { urls in
        self.parent?.received.send(urls)
      }
    }
    func dropInteraction(_ interaction: UIDropInteraction, sessionDidEnter session: UIDropSession) {
      parent?.enter.send(session)
    }
    func dropInteraction(_ interaction: UIDropInteraction, sessionDidExit session: UIDropSession) {
      parent?.leave.send(session)
    }
    func dropInteraction(_ interaction: UIDropInteraction, sessionDidEnd session: UIDropSession) {
      parent?.leave.send(session)
      parent?.end.send(session)
    }
  }
}
public struct FileDrop {
  fileprivate var interaction: FileDropInteraction
  fileprivate var bag: PipeStorage
  @discardableResult
  public func enter(_ action: @escaping (UIDropSession)->()) -> Self {
    interaction.enter.forEach(action).store(in: interaction)
    return self
  }
  @discardableResult
  public func leave(_ action: @escaping (UIDropSession)->()) -> Self {
    interaction.leave.forEach(action).store(in: interaction)
    return self
  }
  @discardableResult
  public func end(_ action: @escaping (UIDropSession)->()) -> Self {
    interaction.end.forEach(action).store(in: interaction)
    return self
  }
}

extension UIDropSession {
  func containsUrl() -> Bool {
    items.contains { $0.itemProvider.registeredTypeIdentifiers.contains(where: { $0.starts(with: "public.") || $0.starts(with: "dyn.") }) }
  }
  func loadFileUrls(_ completion: @escaping ([FileURL])->()) {
    items.map(\.itemProvider).createFileUrls(completion)
  }
}
public extension Array where Element == NSItemProvider {
  func enumerateUrls(_ completion: @escaping (URL?, Int)->()) {
    let filter: (String)->Bool = { $0.starts(with: "public.") || $0.starts(with: "dyn.") }
    let items: [(NSItemProvider, String)] = compactMap {
      guard let type = $0.registeredTypeIdentifiers.first(where: filter)
              ?? $0.registeredTypeIdentifiers.first else { return nil }
      return ($0, type)
    }
    items.forEach { item in
      item.0.loadFileRepresentation(forTypeIdentifier: item.1) { url, error in
        completion(url, items.count)
      }
    }
  }
  func createFileUrls(_ completion: @escaping ([FileURL]) -> ()) {
    var urls = [FileURL]()
    var processed = 0
    let directory = Data.random(32).hex.tempURL
    directory.create(directory: true, subdirectories: false)
    enumerateUrls { url, count in
      if let old = url {
        let new = directory + old.lastPathComponent
        old.fileURL.copy(to: new)
        thread.lock {
          urls.append(new)
        }
      }
      thread.lock {
        processed += 1
        if processed == count {
          let u = urls
          urls.removeAll()
          mainThread {
            completion(u)
          }
        }
      }
    }
  }
}
#endif
