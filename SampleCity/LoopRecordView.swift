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
  
  weak var parent: HomeViewController?
  
  var isWhite = true
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
  
  func toggleRed() {
    self.isWhite = !self.isWhite
    self.label.textColor = self.isWhite ? Constants.whiteColor : Constants.redColor
  }
  
  func didChangeIsArmed(isArmed: Bool) {
    self.setArmed(isArmed)
  }
  
  func didChangeIsLoopRecording(isLoopRecording: Bool) {
    if isLoopRecording {
      self.armedTimer?.invalidate()
      self.label.textColor = Constants.redColor
      self.isWhite = false
    } else {
      self.label.textColor = Constants.whiteColor
      self.isWhite = true
      self.setArmed(false)
    }
  }
  
  func setArmed(armed: Bool) {
    if armed {
      self.label.textColor = Constants.redColor
      self.isWhite = false
      let interval = 0.35
      self.armedTimer = NSTimer.scheduledTimerWithTimeInterval(interval, target: self, selector: #selector(LoopRecordView.toggleRed), userInfo: nil, repeats: true)
      self.armedTimer?.tolerance = interval * 0.10
    } else {
      self.armedTimer?.invalidate()
      self.label.textColor = Constants.whiteColor
      self.isWhite = true
    }
  }
}
