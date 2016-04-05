//
//  LoopPlaybackDelegate.swift
//  SampleCity
//
//  Created by Alexander Katz on 3/31/16.
//  Copyright © 2016 Alexander Katz. All rights reserved.
//

import Foundation

protocol LoopPlaybackDelegate: class, Disablable {
  var loopExists: Bool { get set }
  var isPlayingLoop: Bool { get set }
}