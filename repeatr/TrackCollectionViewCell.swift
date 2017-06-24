//
//  WaveformCollectionViewCell.swift
//  SampleCity
//
//  Created by Alexander Katz on 4/3/16.
//  Copyright © 2016 Alexander Katz. All rights reserved.
//

import UIKit

class TrackCollectionViewCell: UICollectionViewCell, PlaybackVisualDelegate {

  static let identifier = "TrackCollectionViewCell"
  
  fileprivate lazy var label: UILabel = LayoutHelper.createInfoLabel()
  fileprivate lazy var volumeControlView: VolumeControlView = self.createVolumeControlView()
  fileprivate lazy var trackControlsView: UIView = self.createTrackControlsView()
  fileprivate lazy var playbackView: LoopPlaybackView = self.createPlaybackView()
  fileprivate lazy var removeTrackView: RemoveTrackView = self.createRemoveTrackView()
  
  fileprivate var bottomSelectedBorder: UIView!
  fileprivate var topSelectedBorder: UIView!
  
  var track: Track? {
    didSet {
      oldValue?.waveformView.removeFromSuperview()
      self.trackControlsView.alpha = (!self.editing || self.track?.waveformView.audioURL == nil) ? 0 : 1
      if let track = self.track {
        self.addWaveformView(track.waveformView)
        self.bringSubview(toFront: self.volumeControlView)
        
        self.volumeControlView.delegate = track
        self.volumeControlView.volumeLevel = track.volumeLevel
        self.playbackView.trackService = track.trackService
        self.removeTrackView.trackService = track.trackService
      }
    }
  }
  
  var editing = false {
    didSet {
      if let track = self.track {
        self.volumeControlView.volumeLevel = track.volumeLevel
        
        if self.editing {
          self.playbackView.trackService = track.trackService
          self.removeTrackView.trackService = track.trackService
          track.trackService.loopPlaybackDelegate = self.playbackView
          self.bringSubview(toFront: self.trackControlsView)
        }
      }
      self.track?.waveformView.enabled = !self.editing
      self.track?.waveformView.dimmed = self.editing
      self.trackControlsView.alpha = self.editing ? 1 : 0
    }
  }
  
  var enabled = true {
    didSet {
      self.track?.waveformView.enabled = self.enabled
      self.track?.waveformView.dimmed = !self.enabled
    }
  }
  
  var selectedForLoopRecord = false {
    didSet {
      self.track?.waveformView.backgroundColor = self.selectedForLoopRecord ? Constants.blackSelectedColor : Constants.blackColor
    }
  }
  
  fileprivate func setSelectedBordersVisible(_ visible: Bool) {
    if self.bottomSelectedBorder == nil {
      
    }
  }

  fileprivate func addWaveformView(_ waveformView: WaveformView) {
    waveformView.backgroundColor = UIColor.black
    waveformView.translatesAutoresizingMaskIntoConstraints = false
    
    self.addSubview(waveformView)
    
    waveformView.leadingAnchor.constraint(equalTo: self.leadingAnchor).isActive = true
    waveformView.trailingAnchor.constraint(equalTo: self.trailingAnchor).isActive = true
    waveformView.topAnchor.constraint(equalTo: self.topAnchor).isActive = true
    waveformView.bottomAnchor.constraint(equalTo: self.bottomAnchor).isActive = true
  }
  
  fileprivate func createTrackControlsView() -> UIView {
    let view = UIView()
    view.translatesAutoresizingMaskIntoConstraints = false
    self.addSubview(view)
    
    view.rightAnchor.constraint(equalTo: self.rightAnchor).isActive = true
    view.leftAnchor.constraint(equalTo: self.leftAnchor).isActive = true
    view.topAnchor.constraint(equalTo: self.topAnchor).isActive = true
    view.bottomAnchor.constraint(equalTo: self.bottomAnchor).isActive = true
    
    view.alpha = 0
    
    return view
  }
  
  fileprivate func createPlaybackView() -> LoopPlaybackView {
    let playbackView = LoopPlaybackView()
    playbackView.translatesAutoresizingMaskIntoConstraints = false
    self.trackControlsView.addSubview(playbackView)
    
    playbackView.heightAnchor.constraint(equalToConstant: CGFloat(Constants.recordButtonHeight)).isActive = true
    playbackView.widthAnchor.constraint(equalTo: self.trackControlsView.widthAnchor, multiplier: 0.25).isActive = true
    playbackView.leadingAnchor.constraint(equalTo: self.trackControlsView.leadingAnchor).isActive = true
    playbackView.bottomAnchor.constraint(equalTo: self.trackControlsView.bottomAnchor).isActive = true
    playbackView.enabled = true
    playbackView.visualDelegate = self
    
    return playbackView
  }
  
  fileprivate func createRemoveTrackView() -> RemoveTrackView {
    let removeTrackView = RemoveTrackView()
    removeTrackView.translatesAutoresizingMaskIntoConstraints = false
    self.trackControlsView.addSubview(removeTrackView)
    
    removeTrackView.heightAnchor.constraint(equalToConstant: CGFloat(Constants.recordButtonHeight)).isActive = true
    removeTrackView.widthAnchor.constraint(equalTo: self.trackControlsView.widthAnchor, multiplier: 0.25).isActive = true
    removeTrackView.leadingAnchor.constraint(equalTo: self.playbackView.trailingAnchor).isActive = true
    removeTrackView.bottomAnchor.constraint(equalTo: self.trackControlsView.bottomAnchor).isActive = true
    removeTrackView.trackService = self.track?.trackService
    
    return removeTrackView
  }
  
  fileprivate func createVolumeControlView() -> VolumeControlView {
    let volumeView = VolumeControlView()
    volumeView.translatesAutoresizingMaskIntoConstraints = false
    self.trackControlsView.addSubview(volumeView)
    
    volumeView.rightAnchor.constraint(equalTo: self.trackControlsView.rightAnchor).isActive = true
    volumeView.heightAnchor.constraint(equalTo: self.trackControlsView.heightAnchor).isActive = true
    volumeView.bottomAnchor.constraint(equalTo: self.trackControlsView.bottomAnchor).isActive = true
    volumeView.leftAnchor.constraint(equalTo: self.trackControlsView.leftAnchor).isActive = true
    volumeView.backgroundColor = Constants.whiteColor.withAlphaComponent(0)
    volumeView.fillColor = Constants.whiteColor.withAlphaComponent(Constants.dimAlpha)
    volumeView.centerLabelText = nil
    return volumeView
  }
  
  // PlaybackVisualDelegate
  
  func playbackView(_ playbackView: LoopPlaybackView, isPlayingLoop: Bool) {
    self.volumeControlView.fillColor = isPlayingLoop ? Constants.greenColor.withAlphaComponent(Constants.dimAlpha) : Constants.whiteColor.withAlphaComponent(Constants.dimAlpha)
  }
}
