//
//  AudioVolumeDelegate.swift
//  SampleCity
//
//  Created by Alexander Katz on 4/15/16.
//  Copyright © 2016 Alexander Katz. All rights reserved.
//

import Foundation

protocol AudioVolumeDelegate: class {
  var volumeLevel: Float { get set }
}