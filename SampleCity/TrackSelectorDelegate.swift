//
//  TrackSelectorDelegate.swift
//  SampleCity
//
//  Created by Alexander Katz on 4/5/16.
//  Copyright © 2016 Alexander Katz. All rights reserved.
//

import Foundation

protocol TrackSelectorDelegate: class {
  var editingTracks: Bool { get }
  func setTrackEditModeEnabled(enabled: Bool, animated: Bool)
}