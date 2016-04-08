//
//  LoopRecordView.swift
//  SampleCity
//
//  Created by Alexander Katz on 3/26/16.
//  Copyright © 2016 Alexander Katz. All rights reserved.
//

import UIKit

class LoopRecordView: ControlLabelView, LoopRecordDelegate {
  
  private let loopText = "LOOP"
  
  var isArmed = false {
    didSet {
      if self.isArmed {
        self.isWhite = false
        let interval = 0.35
        self.armedTimer = NSTimer.scheduledTimerWithTimeInterval(interval, target: self, selector: #selector(LoopRecordView.toggleArmed), userInfo: nil, repeats: true)
        self.armedTimer?.tolerance = interval * 0.10
      } else {
        self.armedTimer?.invalidate()
        self.isWhite = true
      }
    }
  }
  
  var isLoopRecording = false {
    didSet {
      if self.isLoopRecording {
        self.armedTimer?.invalidate()
        self.isWhite = false
      } else {
        self.isWhite = true
        self.isArmed = false
      }
    }
  }
  
  var isWhite = false {
    didSet {
      self.label.textColor = self.isWhite ? Constants.whiteColor : Constants.redColor
    }
  }
  
  var armedTimer: NSTimer?
  
  override func touchesBegan(touches: Set<UITouch>, withEvent event: UIEvent?) {
    if let trackService = self.trackService {
      if trackService.isLoopRecording {
        trackService.finishLoopRecord()
      } else if !trackService.isArmedForLoopRecord {
        trackService.isArmedForLoopRecord = true
      } else if trackService.isArmedForLoopRecord && !trackService.isLoopRecording {
        trackService.startLoopRecord()
      }
    }
  }
  
  override func setup() {
    self.enabled = false
    self.label.text = self.loopText
  }
  
  func toggleArmed() {
    self.isWhite = !self.isWhite
  }
  
}
