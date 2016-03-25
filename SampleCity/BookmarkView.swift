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
  
  var percentX: CGFloat? {
    get {
      if let superview = self.superview {
        return self.center.x / superview.bounds.width
      }
      
      return nil
    }
  }
  
  override init(frame: CGRect) {
    super.init(frame: frame)
    self.addCursorView()
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
    self.cursorView.backgroundColor = Constants.blackColorTransparent
    self.addSubview(self.cursorView)
    
    let horizontal = self.cursorView.centerXAnchor.constraintEqualToAnchor(self.centerXAnchor)
    let vertical = self.cursorView.centerYAnchor.constraintEqualToAnchor(self.centerYAnchor)
    let width = self.cursorView.widthAnchor.constraintEqualToAnchor(nil, constant: 5)
    let height = self.cursorView.heightAnchor.constraintEqualToAnchor(self.heightAnchor)
    
    NSLayoutConstraint.activateConstraints([horizontal, vertical, width, height])
  }
}
