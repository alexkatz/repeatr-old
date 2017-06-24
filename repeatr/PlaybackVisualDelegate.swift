//
//  PlaybackVisualDelegate.swift
//  SampleCity
//
//  Created by Alexander Katz on 4/26/16.
//  Copyright © 2016 Alexander Katz. All rights reserved.
//

import Foundation

protocol PlaybackVisualDelegate: class {
  func playbackView(_ playbackView: LoopPlaybackView, isPlayingLoop: Bool)
}
