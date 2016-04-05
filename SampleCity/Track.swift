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
    
    self.waveformView.waveColor = Constants.whiteColor.colorWithAlphaComponent(Constants.dimAlpha)
    self.waveformView.cursorColor = Constants.whiteColor.colorWithAlphaComponent(Constants.dimmerAlpha)
    self.waveformView.bookmarkColor = Constants.whiteColor.colorWithAlphaComponent(Constants.dimAlpha)
    self.waveformView.bookmarkBaseColor = Constants.whiteColor.colorWithAlphaComponent(Constants.dimmerAlpha)
  }
  
}