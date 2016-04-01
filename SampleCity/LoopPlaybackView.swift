//
//  LoopPlaybackView.swift
//  SampleCity
//
//  Created by Alexander Katz on 3/31/16.
//  Copyright © 2016 Alexander Katz. All rights reserved.
//

import UIKit

class LoopPlaybackView: UIView, LoopPlaybackDelegate {
  
  private let audioService = AudioService.sharedInstance
  
  var isPlayingLoop = false {
    didSet {
      self.backgroundColor = self.isPlayingLoop ? Constants.greenColor : Constants.redColor
    }
  }
  
  override func touchesBegan(touches: Set<UITouch>, withEvent event: UIEvent?) {
    if self.audioService.isPlayingLoop {
      self.audioService.pauseLoopPlayback()
    } else {
      self.audioService.startLoopPlayback()
    }
  }
  
}
