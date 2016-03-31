//
//  LoopRecordView.swift
//  SampleCity
//
//  Created by Alexander Katz on 3/26/16.
//  Copyright © 2016 Alexander Katz. All rights reserved.
//

import UIKit

class LoopRecordView: UIView, LoopRecordDelegate {
  
  private let audioService = AudioService.sharedInstance
  
  var isArmed = false {
    didSet {
      if self.isArmed {
        self.isDimmed = true
        let interval = 0.35
        self.armedTimer = NSTimer.scheduledTimerWithTimeInterval(interval, target: self, selector: #selector(LoopRecordView.toggleArmed), userInfo: nil, repeats: true)
        self.armedTimer?.tolerance = interval * 0.10
      } else {
        self.armedTimer?.invalidate()
        self.isDimmed = false
      }
    }
  }
  
  var isLoopRecording = false {
    didSet {
      if self.isLoopRecording {
        self.armedTimer?.invalidate()
        self.isDimmed = true
      } else {
        self.isDimmed = false
        self.isArmed = false
      }
    }
  }
  
  var isDimmed = false {
    didSet {
      self.backgroundColor = Constants.redColor.colorWithAlphaComponent(self.isDimmed ? 0.8 : 1)
    }
  }
  
  var armedTimer: NSTimer?
  
  override func touchesBegan(touches: Set<UITouch>, withEvent event: UIEvent?) {
    if !self.audioService.isArmedForLoopRecord {
      self.audioService.isArmedForLoopRecord = true
    } else if self.audioService.isArmedForLoopRecord && !self.audioService.isLoopRecording {
      self.audioService.isLoopRecording = true
    } else if self.audioService.isLoopRecording {
      self.audioService.isLoopRecording = false
    }
  }
  
  func toggleArmed() {
    self.isDimmed = !self.isDimmed
  }
  
}
