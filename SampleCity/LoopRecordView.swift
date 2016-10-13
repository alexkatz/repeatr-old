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
  var armedTimer: Timer?
  
  override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
    if let trackService = self.trackService {
      if trackService.isLoopRecording {
        trackService.finishLoopRecord()
        self.parent?.dismissActiveLoopRecord()
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
    self.backgroundColor = Constants.redColor
  }
  
  func toggleRed() {
    self.isWhite = !self.isWhite
    self.label.textColor = self.isWhite ? Constants.whiteColor : Constants.blackColor
  }
  
  func didChangeIsArmed(_ isArmed: Bool) {
    self.setArmed(isArmed)
  }
  
  func didChangeIsLoopRecording(_ isLoopRecording: Bool) {
    if isLoopRecording {
      self.armedTimer?.invalidate()
      self.label.textColor = Constants.blackColor
      self.isWhite = false
    } else {
      self.label.textColor = Constants.whiteColor
      self.backgroundColor = Constants.redColor
      self.isWhite = true
      self.setArmed(false)
    }
  }
  
  func setArmed(_ armed: Bool) {
    if armed {
      self.label.textColor = Constants.blackColor
      self.backgroundColor = Constants.redColor.withAlphaComponent(0.7)
      self.isWhite = false
      let interval = 0.35
      self.armedTimer = Timer.scheduledTimer(timeInterval: interval, target: self, selector: #selector(LoopRecordView.toggleRed), userInfo: nil, repeats: true)
      self.armedTimer?.tolerance = interval * 0.10
    } else {
      self.armedTimer?.invalidate()
      self.label.textColor = Constants.whiteColor
      self.isWhite = true
    }
  }
}
