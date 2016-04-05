//
//  RecordDelegate.swift
//  SampleCity
//
//  Created by Alexander Katz on 3/21/16.
//  Copyright © 2016 Alexander Katz. All rights reserved.
//

import Foundation

protocol RecordDelegate: class, Disablable {
  var isRecording: Bool { get set }
}