//
//  ViewController.swift
//  SampleCity
//
//  Created by Alexander Katz on 3/19/16.
//  Copyright © 2016 Alexander Katz. All rights reserved.
//

import UIKit
import AVFoundation

class HomeViewController: UIViewController, UICollectionViewDataSource, UICollectionViewDelegate, TrackSelectorDelegate {
  
  private var tracks = [Track]()
  private var loopRecordViewActiveConstraints = [NSLayoutConstraint]()
  private var collectionViewOffset: CGPoint?
  private var selectedTrack: Track?
  private var didInitialize = false
  
  private lazy var newTrackView: UIView = self.createNewTrackView()
  
  @IBOutlet weak var recordView: RecordView!
  @IBOutlet weak var collectionView: UICollectionView!
  @IBOutlet weak var loopRecordView: LoopRecordView!
  @IBOutlet weak var trackAccessView: TrackAccessView!
  @IBOutlet weak var muteAllView: MuteAllView!
  @IBOutlet weak var loopRecordCancelView: LoopRecordCancelView!
  
  @IBOutlet var loopRecordViewPassiveConstraints: [NSLayoutConstraint]!
  
  var editingTracks = false
  
  // MARK: Overrides
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    do {
      let audioSession = AVAudioSession.sharedInstance()
      try audioSession.setCategory(AVAudioSessionCategoryPlayAndRecord, with: AVAudioSessionCategoryOptions.defaultToSpeaker)
      try audioSession.setPreferredIOBufferDuration(0.001)
      try AVAudioSession.sharedInstance().setActive(true)
    } catch let error as NSError {
      print("Error starting audio session: \(error.localizedDescription)")
    }
    
    self.trackAccessView.delegate = self
    
    self.collectionView.register(TrackCollectionViewCell.self, forCellWithReuseIdentifier: TrackCollectionViewCell.identifier)
    self.collectionView.delegate = self
    self.collectionView.dataSource = self
    
    self.loopRecordCancelView.isHidden = true
    self.loopRecordCancelView.parent = self
    
    self.loopRecordView.parent = self
    let insets = UIEdgeInsets(top: Constants.cellHeight, left: 0, bottom: 0, right: 0)
    self.loopRecordViewActiveConstraints.append(self.loopRecordView.topAnchor.constraint(equalTo: self.view.topAnchor, constant: insets.top))
    self.loopRecordViewActiveConstraints.append(self.loopRecordView.leftAnchor.constraint(equalTo: self.view.leftAnchor, constant: insets.left))
    self.loopRecordViewActiveConstraints.append(self.loopRecordView.rightAnchor.constraint(equalTo: self.view.rightAnchor, constant: insets.right))
    self.loopRecordViewActiveConstraints.append(self.loopRecordView.bottomAnchor.constraint(equalTo: self.view.bottomAnchor, constant: insets.bottom))
    for constraint in self.loopRecordViewActiveConstraints {
      constraint.priority = 900
      constraint.isActive = true
    }
  }
  
  override func viewDidLayoutSubviews() {
    super.viewDidLayoutSubviews()
    if !(self.collectionView.collectionViewLayout is WaveformCollectionViewLayout) {
      self.setCollectionViewLayoutWithSize(self.collectionView.bounds.size)
    }
  }
  
  override func viewDidAppear(_ animated: Bool) {
    super.viewDidAppear(animated)
    NotificationCenter.default.addObserver(self, selector: #selector(HomeViewController.onTrackSelected(_:)), name: NSNotification.Name(rawValue: Constants.notificationTrackSelected), object: nil)
    NotificationCenter.default.addObserver(self, selector: #selector(HomeViewController.onLoopRecordArmed(_:)), name: NSNotification.Name(rawValue: Constants.notificationLoopRecordArmed), object: nil)
    NotificationCenter.default.addObserver(self, selector: #selector(HomeViewController.onDestroyTrack(_:)), name: NSNotification.Name(rawValue: Constants.notificationDestroyTrack), object: nil)
    NotificationCenter.default.addObserver(self, selector: #selector(HomeViewController.dismissActiveLoopRecord), name: NSNotification.Name(rawValue: Constants.notificationEndLoopRecord), object: nil)
  }
  
  override func viewWillDisappear(_ animated: Bool) {
    super.viewWillDisappear(animated)
    NotificationCenter.default.removeObserver(self)
  }
  
  override var prefersStatusBarHidden : Bool {
    return true
  }
  
  // MARK: Methods
  
  func toggleTrackEditMode() {
    if self.tracks.count > 0 {
      self.editingTracks = !self.editingTracks
      UIView.animate(withDuration: Constants.defaultAnimationDuration, delay: 0, options: [.allowUserInteraction, .beginFromCurrentState], animations: {
        for cell in self.visibleCells() {
          cell.editing = self.editingTracks
        }
        }, completion: nil)
    }
  }
  
  
  func createTrack() {
    let newTrack = Track()
    self.collectionView.performBatchUpdates({
      self.tracks.insert(newTrack, at: 0)
      self.collectionView.insertItems(at: [IndexPath(item: 0, section: 0)])
      }, completion: { finished in
        if finished {
          for cell in self.visibleCells() {
            if cell.track == self.tracks.first {
              UIView.animate(withDuration: 0.35, delay: 0, options: [.allowUserInteraction, .beginFromCurrentState], animations: {
                self.selectCell(cell)
                }, completion: nil)
              break
            }
          }
        }
    })
  }
  
  func onDestroyTrack(_ notification: Notification) {
    if let selectedTrackServiceUUID = (notification as NSNotification).userInfo?[Constants.trackServiceUUIDKey] as? String {
      for cell in self.visibleCells() {
        if cell.track?.trackService.uuid == selectedTrackServiceUUID, let indexPath = self.collectionView.indexPath(for: cell) {
          self.collectionView.performBatchUpdates({
            if let track = cell.track, let trackIndex = self.tracks.index(of: track) {
              if track.trackService.isPlayingLoop {
                track.trackService.removeFromLoopPlayback()
              }
              self.collectionView.deleteItems(at: [indexPath])
              self.tracks.remove(at: trackIndex)
            }
            }, completion: nil)
          break
        }
      }
    }
  }
  
  func onTrackSelected(_ notification: Notification) {
    if let selectedUUID = (notification as NSNotification).userInfo?[Constants.trackServiceUUIDKey] as? String {
      for cell in self.visibleCells() {
        if cell.track?.trackService.uuid == selectedUUID {
          if !cell.selectedForLoopRecord {
            self.selectCell(cell)
            for cell in self.visibleCells() {
              cell.track?.trackService.isArmedForLoopRecord = false
            }
          }
          break
        }
      }
    }
  }
  
  func onLoopRecordArmed(_ notification: Notification) {
    DispatchQueue.main.async {
      for cell in self.visibleCells() {
        if let track = cell.track , track.trackService.isArmedForLoopRecord {
          track.trackService.removeFromLoopPlayback()
          cell.enabled = true
          self.collectionView.isScrollEnabled = false
          UIView.animate(
            withDuration: 0.5,
            delay: 0,
            usingSpringWithDamping: 0.6,
            initialSpringVelocity: 0.3,
            options: .curveEaseInOut,
            animations: {
              for constraint in self.loopRecordViewPassiveConstraints {
                constraint.isActive = false
              }
              self.view.layoutIfNeeded()
              self.loopRecordCancelView.isHidden = false
            },
            completion: { finished in
              
          })
          self.collectionView.setContentOffset(CGPoint(x: 0, y: cell.frame.origin.y), animated: false)
        } else {
          cell.enabled = false
        }
      }
    }
  }
  
  func dismissActiveLoopRecord() {
    DispatchQueue.main.async {
      for cell in self.visibleCells() {
        cell.track?.trackService.isArmedForLoopRecord = false
      }
      self.collectionView.isScrollEnabled = true
      UIView.animate(
        withDuration: 0.5,
        delay: 0,
        usingSpringWithDamping: 0.6,
        initialSpringVelocity: 0.3,
        options: .curveEaseInOut,
        animations: {
          self.loopRecordCancelView.isHidden = true
          UIView.animate(withDuration: 0.35) {
            for constraint in self.loopRecordViewPassiveConstraints {
              constraint.isActive = true
            }
            self.view.layoutIfNeeded()
          }
        },
        completion: { finished in
          
      })
    }
  }
  
  func onFinishedLoopRecording(_ notification: Notification) {
    
  }
  
  fileprivate func visibleCells() -> [TrackCollectionViewCell] {
    return self.collectionView.visibleCells.map({ cell in cell as! TrackCollectionViewCell })
  }
  
  fileprivate func setCollectionViewLayoutWithSize(_ size: CGSize, animated: Bool = false) {
    let layout = TracksCollectionViewLayout(bounds: size)
    self.collectionView.setCollectionViewLayout(layout, animated: animated)
  }
  
  fileprivate func selectCell(_ cell: TrackCollectionViewCell) {
    if self.selectedTrack != cell.track {
      cell.track?.trackService.recordDelegate = self.recordView
      cell.track?.trackService.loopRecordDelegate = self.loopRecordView
      cell.track?.trackService.trackAccessDelegate = self.trackAccessView
      self.recordView.trackService = cell.track?.trackService
      self.loopRecordView.trackService = cell.track?.trackService
      
      cell.selectedForLoopRecord = true
      self.selectedTrack = cell.track
      
      for visibleCell in self.visibleCells() {
        visibleCell.selectedForLoopRecord = visibleCell == cell
        visibleCell.enabled = true
        visibleCell.editing = false
        visibleCell.track?.trackService.isArmedForLoopRecord = false
        self.loopRecordView.setArmed(false)
      }
      self.editingTracks = false
      self.loopRecordView.setArmed(false)
      self.loopRecordView.enabled = cell.track?.trackService.hasAudio ?? false
      self.recordView.enabled = true
    }
  }
  
  // TODO: new track thing that subtly appears when you pull down on collectionview
  fileprivate func createNewTrackView() -> UIView {
    let view = UIView()
    
    return view
  }
  
  // MARK: UICollectionViewDataSource
  
  func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
    return self.tracks.count
  }
  
  func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
    let cell = collectionView.dequeueReusableCell(withReuseIdentifier: TrackCollectionViewCell.identifier, for: indexPath) as! TrackCollectionViewCell
    cell.track = self.tracks[(indexPath as NSIndexPath).item]
    
    if !self.didInitialize && self.tracks.count == 1 {
      self.selectCell(cell)
      self.didInitialize = true
    }
    
    cell.selectedForLoopRecord = cell.track == self.selectedTrack
    cell.editing = self.tracks[(indexPath as NSIndexPath).item].waveformView.dimmed
    
    return cell
  }
  
  // MARK: UICollectionViewDelegate
  
  func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
    if let cell = collectionView.cellForItem(at: indexPath) as? TrackCollectionViewCell {
      self.selectCell(cell)
    }
  }
  
  func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
    if scrollView.contentOffset.y < -50 {
      self.createTrack()
    }
  }
  
  func scrollViewDidScroll(_ scrollView: UIScrollView) {
    
  }
  
}

