//
//  File.swift
//  
//
//  Created by Dmitry Kozlov on 5/4/20.
//

protocol SingleItemSync: AnyObject {
  associatedtype Value
  var local: Value? { get set }
  var loading: O<Value>? { get set }
  func load() -> Future<Value>
  func isOutdated(_ value: Value) -> Bool
}
extension SingleItemSync {
  /// Loads new value if current is outdated
  func get() -> O<Value> {
    if let loading = loading {
      return loading
    } else if let local = local, !isOutdated(local) {
      return O<Value>(local)
    } else {
      let h = O(local)
      load().pipe(h)
      return h
    }
  }
  
  func getNoUpdate() -> O<Value> {
    if let loading = loading {
      return loading
    } else if let local = local, !isOutdated(local) {
      return O<Value>(local)
    } else {
      let h = O(local)
      load().pipe(h)
      return h
    }
  }
  
  /// Loads new value on every request.
  func getAndUpdate() -> O<Value> {
    loading.lazy { () -> O<Value> in
      let h = O<Value>()
      h.osend(local)
      load().pipe(h)
      return h
    }
  }
}
