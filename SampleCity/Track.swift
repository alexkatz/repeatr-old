//
//  Track.swift
//  SampleCity
//
//  Created by Alexander Katz on 4/4/16.
//  Copyright © 2016 Alexander Katz. All rights reserved.
//

import Foundation

class Track {
  
  var audioService: AudioService
  var waveformView: WaveformView
  
  
  init(audioService: AudioService) {
    self.audioService = audioService
    self.waveformView = WaveformView()
  }
  
}