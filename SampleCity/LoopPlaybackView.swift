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
  
  private var touch: UITouch?
  
  weak var visualDelegate: PlaybackVisualDelegate?
  
  var isPlayingLoop = false {
    didSet {
      self.label.text = self.isPlayingLoop ? self.playingText : self.pausedText
      self.label.textColor = self.isPlayingLoop ? Constants.greenColor : Constants.whiteColor
      self.visualDelegate?.playbackView(self, isPlayingLoop: self.isPlayingLoop)
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
    self.touch = touches.first
  }
  
  override func touchesEnded(touches: Set<UITouch>, withEvent event: UIEvent?) {
    if self.touch == touches.first, let touch = self.touch where self.bounds.contains(touch.locationInView(self)) {
      if self.trackService != nil && self.trackService!.isPlayingLoop {
        self.trackService?.removeFromLoopPlayback()
      } else {
        self.trackService?.addToLoopPlayback()
      }
      self.touch = nil
    }
  }
  
  override func setup() {
    self.label.text = self.pausedText
    self.enabled = false
  }
  
}
