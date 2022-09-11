//
//  File.swift
//  
//
//  Created by Dmitry Kozlov on 13.05.2021.
//

import Foundation

public struct YouTubeURL {
  public let id: String
  public let url: URL
  public var imageUrl: URL {
    URL(string: "https://img.youtube.com/vi/\(id)/0.jpg")!
  }
  public var videoUrl: URL {
    URL(string: "https://www.youtube.com/embed/\(id)")!
  }
  public init?(_ string: String) {
    guard let components = URLComponents(string: string)
      else { return nil }
    self.init(components)
  }
  public init?(_ components: URLComponents) {
    guard let host = components.host else { return nil }
    guard let url = components.url else { return nil }
    self.url = url
    if host.contains("youtube.") {
      guard let id = components.queryItems?
        .first(where: { $0.name == "v" })?.value
      else { return nil }
      self.id = id
    } else if host.contains("youtu.be") {
      self.id = components.path
    } else {
      return nil
    }
  }
}
public struct VideoURL {
  public let url: URL
  public init?(_ string: String) {
    guard let components = URLComponents(string: string)
      else { return nil }
    self.init(components)
  }
  public init?(_ components: URLComponents) {
    guard let url = components.url else { return nil }
    guard FileURL(url).isVideo else { return nil }
    self.url = url
  }
  public init(_ url: URL) {
    self.url = url
  }
}
public struct ImageURL {
  public let url: URL
  public init?(_ string: String) {
    guard let components = URLComponents(string: string)
      else { return nil }
    self.init(components)
  }
  public init?(_ components: URLComponents) {
    guard let url = components.url else { return nil }
    guard FileURL(url).isImage else { return nil }
    self.url = url
  }
}

