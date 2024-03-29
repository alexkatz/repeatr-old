//
//  Track.swift
//  SampleCity
//
//  Created by Alexander Katz on 4/4/16.
//  Copyright © 2016 Alexander Katz. All rights reserved.
//

import Foundation

class Track: AudioVolumeDelegate, Equatable {
  
  var trackService: TrackService
  var waveformView: WaveformView
  
  let uuid = UUID().uuidString
  
  var volumeLevel: Float {
    get {
      return self.trackService.volumeLevel
    }
    set {
      self.trackService.volumeLevel = newValue
    }
  }
  
  convenience init() {
    self.init(trackService: TrackService())
  }
  
  init(trackService: TrackService) {
    self.trackService = trackService
    self.waveformView = WaveformView(trackService: trackService)
    
    self.waveformView.waveColor = Constants.whiteColor.withAlphaComponent(Constants.dimAlpha)
    self.waveformView.cursorColor = Constants.greenColor
    self.waveformView.bookmarkColor = Constants.whiteColor.withAlphaComponent(Constants.dimAlpha)
    self.waveformView.bookmarkBaseColor = Constants.whiteColor.withAlphaComponent(0.0)
    
    self.trackService.playbackDelegate = self.waveformView
    self.trackService.meterDelegate = self.waveformView
  }
  
}

func ==(lhs: Track, rhs: Track) -> Bool {
  return lhs.uuid == rhs.uuid
}
