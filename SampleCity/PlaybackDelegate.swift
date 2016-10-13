//
//  AudioPlaybackDelegate.swift
//  SampleCity
//
//  Created by Alexander Katz on 3/21/16.
//  Copyright © 2016 Alexander Katz. All rights reserved.
//

import Foundation

protocol PlaybackDelegate: class, Disablable {
  var audioURL: URL? { get set }
  var currentTime: TimeInterval? { get set }
  func removeCursor()
}
