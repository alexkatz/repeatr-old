//
//  Track.swift
//  SampleCity
//
//  Created by Alexander Katz on 4/4/16.
//  Copyright © 2016 Alexander Katz. All rights reserved.
//

import Foundation

class Track: AudioVolumeDelegate {
  
  var trackService: TrackService
  var waveformView: WaveformView
  
  var volumeLevel: Float = 1 {
    didSet {
      self.trackService.volumeLevel = self.volumeLevel
    }
  }
  
  convenience init() {
    self.init(trackService: TrackService())
  }
  
  init(trackService: TrackService) {
    self.trackService = trackService
    self.waveformView = WaveformView(trackService: trackService)
    
    self.waveformView.waveColor = Constants.whiteColor.colorWithAlphaComponent(Constants.dimAlpha)
    self.waveformView.cursorColor = Constants.greenColor
    self.waveformView.bookmarkColor = Constants.whiteColor.colorWithAlphaComponent(Constants.dimAlpha)
    self.waveformView.bookmarkBaseColor = Constants.whiteColor.colorWithAlphaComponent(0.2)
  }
  
}