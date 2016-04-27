//
//  BookmarkView.swift
//  SampleCity
//
//  Created by Alexander Katz on 3/23/16.
//  Copyright © 2016 Alexander Katz. All rights reserved.
//

import UIKit

class BookmarkView: UIView {
  
  var cursorView: UIView!
  var percentX: CGFloat?
  var color = UIColor.whiteColor() {
    didSet {
      self.cursorView.backgroundColor = self.color
    }
  }
  
  override init(frame: CGRect) {
    super.init(frame: frame)
    self.addCursorView()
  }
  
  override func layoutSubviews() {
    super.layoutSubviews()
    if let superview = self.superview {
      self.percentX = self.center.x / superview.bounds.width
    }
  }
  
  convenience init() {
    self.init(frame: CGRect.zero)
  }
  
  required init?(coder aDecoder: NSCoder) {
    super.init(coder: aDecoder)
    self.addCursorView()
  }
  
  private func addCursorView() {
    self.cursorView = UIView()
    self.cursorView.translatesAutoresizingMaskIntoConstraints = false
    self.cursorView.backgroundColor = self.color
    self.addSubview(self.cursorView)
    
    let horizontal = self.cursorView.centerXAnchor.constraintEqualToAnchor(self.centerXAnchor)
    let vertical = self.cursorView.centerYAnchor.constraintEqualToAnchor(self.centerYAnchor)
    let width = self.cursorView.widthAnchor.constraintEqualToAnchor(nil, constant: 2)
    let height = self.cursorView.heightAnchor.constraintEqualToAnchor(self.heightAnchor)
    
    NSLayoutConstraint.activateConstraints([horizontal, vertical, width, height])
  }
}
