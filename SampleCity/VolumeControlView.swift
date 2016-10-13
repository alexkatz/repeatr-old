//
//  VolumeControlView.swift
//  SampleCity
//
//  Created by Alexander Katz on 4/15/16.
//  Copyright © 2016 Alexander Katz. All rights reserved.
//

import UIKit

class VolumeControlView: ControlLabelView, UIGestureRecognizerDelegate {
  
  fileprivate var activeTouch: UITouch?
  fileprivate var heightConstraint: NSLayoutConstraint?
  fileprivate var WidthConstraint: NSLayoutConstraint?
  
  fileprivate var filledView = UIView()
  fileprivate var backgroundView = UIView()
  fileprivate var panGestureRecognizer: UIPanGestureRecognizer!
  
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
  
  var centerLabelText: String? {
    didSet {
      self.label.text = self.centerLabelText
      self.label.isHidden = self.centerLabelText == nil
    }
  }
  
  override func layoutSubviews() {
    super.layoutSubviews()
    self.heightConstraint?.constant = self.bounds.height * CGFloat(self.volumeLevel)
    self.WidthConstraint?.constant = self.bounds.width * CGFloat(self.volumeLevel)
  }
  
  override func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
    if let pan = gestureRecognizer as? UIPanGestureRecognizer {
      let velocity = pan.velocity(in: self)
      return abs(velocity.x) > abs(velocity.y)
    }
    
    return false
  }
  
  override func willMove(toWindow newWindow: UIWindow?) {
    super.willMove(toWindow: newWindow)
    if newWindow == nil {
      self.removeGestureRecognizer(self.panGestureRecognizer)
    } else {
      self.heightConstraint?.isActive = true
      self.WidthConstraint?.isActive = true
      self.addGestureRecognizer(self.panGestureRecognizer)
    }
  }
  
  func handlePan(_ recognizer: UIPanGestureRecognizer) {
    let velocityInView = recognizer.velocity(in: self)
    self.volumeLevel += Float(velocityInView.x * 0.0001)
    self.delegate?.volumeLevel = self.volumeLevel
  }
  
  override func setup() {
    self.backgroundView.removeFromSuperview()
    self.filledView.removeFromSuperview()
    
    self.backgroundView.translatesAutoresizingMaskIntoConstraints  = false
    self.addSubview(self.backgroundView)
    
    self.backgroundView.topAnchor.constraint(equalTo: self.topAnchor).isActive = true
    self.backgroundView.leftAnchor.constraint(equalTo: self.leftAnchor).isActive = true
    self.backgroundView.rightAnchor.constraint(equalTo: self.rightAnchor).isActive = true
    self.backgroundView.bottomAnchor.constraint(equalTo: self.bottomAnchor).isActive = true
    
    self.filledView.backgroundColor = Constants.whiteColor.withAlphaComponent(Constants.dimmerAlpha)
    self.filledView.translatesAutoresizingMaskIntoConstraints = false
    self.addSubview(self.filledView)
    
    self.filledView.bottomAnchor.constraint(equalTo: self.bottomAnchor).isActive = true
    self.filledView.leftAnchor.constraint(equalTo: self.leftAnchor).isActive = true
    self.filledView.heightAnchor.constraint(equalToConstant: 2).isActive = true
    self.WidthConstraint = self.filledView.widthAnchor.constraint(equalToConstant: 0)
    
    self.panGestureRecognizer = UIPanGestureRecognizer(target: self, action: #selector(VolumeControlView.handlePan(_:)))
    self.panGestureRecognizer.delegate = self
    
    self.label.text = "TRACK VOLUME"
  }
  
}
