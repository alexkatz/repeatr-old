//
//  LoopPlaybackView.swift
//  SampleCity
//
//  Created by Alexander Katz on 3/31/16.
//  Copyright © 2016 Alexander Katz. All rights reserved.
//

import UIKit

class LoopPlaybackView: ControlLabelView, LoopPlaybackDelegate {
  
  private let playingText = "PLAYING"
  private let pausedText = "PAUSED"

  var isPlayingLoop = false {
    didSet {
      self.label.text = self.isPlayingLoop ? self.playingText : self.pausedText
      self.label.textColor = self.isPlayingLoop ? Constants.greenColor : Constants.whiteColor
    }
  }
  
  var loopExists = false {
    didSet {
      self.enabled = self.loopExists
      if !self.loopExists {
        self.label.text = self.pausedText
      }
    }
  }
  
  override func touchesBegan(touches: Set<UITouch>, withEvent event: UIEvent?) {
    if self.audioService != nil && self.audioService!.isPlayingLoop {
      self.audioService?.pauseLoopPlayback()
    } else {
      self.audioService?.startLoopPlayback()
    }
  }
  
  override func setup() {
    self.label.text = self.pausedText
    self.enabled = false
  }
  
}
