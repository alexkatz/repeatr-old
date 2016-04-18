//
//  VolumeControlView.swift
//  SampleCity
//
//  Created by Alexander Katz on 4/15/16.
//  Copyright © 2016 Alexander Katz. All rights reserved.
//

import UIKit

class VolumeControlView: UIView, UIGestureRecognizerDelegate {
  
  private var activeTouch: UITouch?
  private var heightConstraint: NSLayoutConstraint?
  
  private var filledView = UIView()
  private var backgroundView = UIView()
  private var panGestureRecognizer: UIPanGestureRecognizer!
  
  var fillColor: UIColor? {
    didSet {
      if let fillColor = self.fillColor {
        self.filledView.backgroundColor = fillColor
      }
    }
  }

  weak var delegate: AudioVolumeDelegate?
  
  var volumeLevel: Float = 1 {
    didSet {
      if self.volumeLevel > 1 {
        self.volumeLevel = 1
      } else if self.volumeLevel < 0 {
        self.volumeLevel = 0
      }
      self.delegate?.volumeLevel = self.volumeLevel
      self.setNeedsLayout()
    }
  }
  
  convenience init() {
    self.init(frame: CGRect.zero)
    self.setup()
  }
  
  override init(frame: CGRect) {
    super.init(frame: frame)
    self.setup()
  }
  
  required init?(coder aDecoder: NSCoder) {
    super.init(coder: aDecoder)
    self.setup()
  }
  
  override func layoutSubviews() {
    super.layoutSubviews()
    self.heightConstraint?.constant = self.bounds.height * CGFloat(self.volumeLevel)
  }
  
  override func gestureRecognizerShouldBegin(gestureRecognizer: UIGestureRecognizer) -> Bool {
    if let pan = gestureRecognizer as? UIPanGestureRecognizer {
      let velocity = pan.velocityInView(self)
      return abs(velocity.y) > abs(velocity.x)
    }
    return false
  }
  
  override func willMoveToWindow(newWindow: UIWindow?) {
    super.willMoveToWindow(newWindow)
    if newWindow == nil {
      self.removeGestureRecognizer(self.panGestureRecognizer)
    } else {
      self.heightConstraint?.active = true
      self.addGestureRecognizer(self.panGestureRecognizer)
    }
  }
  
  func handlePan(recognizer: UIPanGestureRecognizer) {
    let velocity = -recognizer.velocityInView(self).y
    self.volumeLevel += Float(velocity * 0.0001)
    self.setNeedsLayout()
  }
  
  private func setup() {
    
    self.backgroundView.translatesAutoresizingMaskIntoConstraints  = false
    self.addSubview(backgroundView)
    
    self.backgroundView.topAnchor.constraintEqualToAnchor(self.topAnchor).active = true
    self.backgroundView.leftAnchor.constraintEqualToAnchor(self.leftAnchor).active = true
    self.backgroundView.rightAnchor.constraintEqualToAnchor(self.rightAnchor).active = true
    self.backgroundView.bottomAnchor.constraintEqualToAnchor(self.bottomAnchor).active = true
    
    self.filledView.backgroundColor = Constants.whiteColor
    self.filledView.translatesAutoresizingMaskIntoConstraints = false
    self.addSubview(self.filledView)
    
    self.filledView.bottomAnchor.constraintEqualToAnchor(self.bottomAnchor).active = true
    self.filledView.leftAnchor.constraintEqualToAnchor(self.leftAnchor).active = true
    self.filledView.rightAnchor.constraintEqualToAnchor(self.rightAnchor).active = true
    self.heightConstraint = self.filledView.heightAnchor.constraintEqualToAnchor(nil)
    
    self.panGestureRecognizer = UIPanGestureRecognizer(target: self, action: #selector(VolumeControlView.handlePan(_:)))
    self.panGestureRecognizer.delegate = self
  }
  
}