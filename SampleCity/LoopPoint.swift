//
//  LoopPoint.swift
//  SampleCity
//
//  Created by Alexander Katz on 4/4/16.
//  Copyright © 2016 Alexander Katz. All rights reserved.
//

import Foundation
import AVFoundation

struct LoopPoint {
  let uuid = NSUUID().UUIDString
  let intervalFromStart: UInt64
  let audioTime: Double?
  let audioPlayer: AVAudioPlayer
}