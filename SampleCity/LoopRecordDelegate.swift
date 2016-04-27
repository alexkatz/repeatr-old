//
//  LoopRecordDelegate.swift
//  SampleCity
//
//  Created by Alexander Katz on 3/29/16.
//  Copyright © 2016 Alexander Katz. All rights reserved.
//

import Foundation

protocol LoopRecordDelegate: class, Disablable {
  func didChangeIsLoopRecording(isLoopRecording: Bool)
  func didChangeIsArmed(isArmed: Bool)
}