//
//  WaveformGestureRecognizer.swift
//  SampleCity
//
//  Created by Alexander Katz on 4/29/16.
//  Copyright © 2016 Alexander Katz. All rights reserved.
//

import UIKit
import UIKit.UIGestureRecognizerSubclass

class WaveformGestureRecognizer: UIGestureRecognizer {
  
  private weak var waveformView: WaveformView?
  
  init(waveformView: WaveformView) {
    self.waveformView = waveformView
    super.init(target: nil, action: nil)
    self.delaysTouchesEnded = false
    self.delaysTouchesBegan = false
  }
  
  override func reset() {
    super.reset()
  }
  
  override func touchesBegan(touches: Set<UITouch>, withEvent event: UIEvent) {
    super.touchesBegan(touches, withEvent: event)
    self.waveformView?.touchesBegan(touches)
  }
  
  override func touchesMoved(touches: Set<UITouch>, withEvent event: UIEvent) {
    super.touchesMoved(touches, withEvent: event)
    self.waveformView?.touchesMoved(touches)
  }
  
  override func touchesEnded(touches: Set<UITouch>, withEvent event: UIEvent) {
    super.touchesEnded(touches, withEvent: event)
    self.waveformView?.touchesEnded(touches)
  }
  
  override func touchesCancelled(touches: Set<UITouch>, withEvent event: UIEvent) {
    super.touchesCancelled(touches, withEvent: event)
  }
  
  override func canBePreventedByGestureRecognizer(preventingGestureRecognizer: UIGestureRecognizer) -> Bool {
    return false
  }
  
}