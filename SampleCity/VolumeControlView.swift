//
//  VolumeControlView.swift
//  SampleCity
//
//  Created by Alexander Katz on 4/15/16.
//  Copyright © 2016 Alexander Katz. All rights reserved.
//

import UIKit

class VolumeControlView: ControlLabelView, UIGestureRecognizerDelegate {
  
  private var activeTouch: UITouch?
  private var heightConstraint: NSLayoutConstraint?
  private var WidthConstraint: NSLayoutConstraint?
  
  private var filledView = UIView()
  private var backgroundView = UIView()
  private var panGestureRecognizer: UIPanGestureRecognizer!
  
  private var horizontalMode = false
  
  var fillColor: UIColor? {
    didSet {
      if let fillColor = self.fillColor {
        self.filledView.backgroundColor = fillColor
      }
    }
  }
  
  weak var delegate: AudioVolumeDelegate? {
    didSet {
      if let delegate = self.delegate {
        self.volumeLevel = delegate.volumeLevel
      }
    }
  }
  
  var volumeLevel: Float = 1 {
    didSet {
      if self.volumeLevel > 1 {
        self.volumeLevel = 1
      } else if self.volumeLevel < 0 {
        self.volumeLevel = 0
      }
      self.setNeedsLayout()
    }
  }
  
  override init(frame: CGRect) {
    self.horizontalMode = true
    super.init(frame: frame)
  }
  
  required init?(coder aDecoder: NSCoder) {
    self.horizontalMode = true
    super.init(coder: aDecoder)
  }
  
  override func layoutSubviews() {
    super.layoutSubviews()
    self.heightConstraint?.constant = self.bounds.height * CGFloat(self.volumeLevel)
    self.WidthConstraint?.constant = self.bounds.width * CGFloat(self.volumeLevel)
  }
  
  override func gestureRecognizerShouldBegin(gestureRecognizer: UIGestureRecognizer) -> Bool {
    return true
  }
  
  override func willMoveToWindow(newWindow: UIWindow?) {
    super.willMoveToWindow(newWindow)
    if newWindow == nil {
      self.removeGestureRecognizer(self.panGestureRecognizer)
    } else {
      self.heightConstraint?.active = true
      self.WidthConstraint?.active = true
      self.addGestureRecognizer(self.panGestureRecognizer)
    }
  }
  
  func handlePan(recognizer: UIPanGestureRecognizer) {
    let velocityInView = recognizer.velocityInView(self)
    let velocity = (self.horizontalMode ? velocityInView.x : -velocityInView.y)
    self.volumeLevel += Float(velocity * 0.0001)
    self.delegate?.volumeLevel = self.volumeLevel
  }
  
  override func setup() {
    self.backgroundView.removeFromSuperview()
    self.filledView.removeFromSuperview()
    
    self.backgroundView.translatesAutoresizingMaskIntoConstraints  = false
    self.addSubview(self.backgroundView)
    
    self.backgroundView.topAnchor.constraintEqualToAnchor(self.topAnchor).active = true
    self.backgroundView.leftAnchor.constraintEqualToAnchor(self.leftAnchor).active = true
    self.backgroundView.rightAnchor.constraintEqualToAnchor(self.rightAnchor).active = true
    self.backgroundView.bottomAnchor.constraintEqualToAnchor(self.bottomAnchor).active = true
    
    self.filledView.backgroundColor = Constants.whiteColor.colorWithAlphaComponent(Constants.dimmerAlpha)
    self.filledView.translatesAutoresizingMaskIntoConstraints = false
    self.addSubview(self.filledView)

    if self.horizontalMode {
      self.filledView.bottomAnchor.constraintEqualToAnchor(self.bottomAnchor).active = true
      self.filledView.leftAnchor.constraintEqualToAnchor(self.leftAnchor).active = true
      self.filledView.topAnchor.constraintEqualToAnchor(self.topAnchor).active = true
      self.WidthConstraint = self.filledView.widthAnchor.constraintEqualToAnchor(nil)
    } else {
      self.filledView.bottomAnchor.constraintEqualToAnchor(self.bottomAnchor).active = true
      self.filledView.leftAnchor.constraintEqualToAnchor(self.leftAnchor).active = true
      self.filledView.rightAnchor.constraintEqualToAnchor(self.rightAnchor).active = true
      self.heightConstraint = self.filledView.heightAnchor.constraintEqualToAnchor(nil)
    }
    
    self.panGestureRecognizer = UIPanGestureRecognizer(target: self, action: #selector(VolumeControlView.handlePan(_:)))
    self.panGestureRecognizer.delegate = self
    
    self.label.text = "VOLUME"
  }
  
}