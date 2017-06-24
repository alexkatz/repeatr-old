//
//  Disablable.swift
//  SampleCity
//
//  Created by Alexander Katz on 4/5/16.
//  Copyright © 2016 Alexander Katz. All rights reserved.
//

import Foundation

protocol Disablable: class {
  var enabled: Bool { get set }
}