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
  private var selectedTrack: Track?
  private var didInitialize = false
  
  private lazy var newTrackView: UIView = self.createNewTrackView()
  
  @IBOutlet weak var recordView: RecordView!
  @IBOutlet weak var collectionView: UICollectionView!
  @IBOutlet weak var loopRecordView: LoopRecordView!
  @IBOutlet weak var trackAccessView: TrackAccessView!
  @IBOutlet weak var muteAllView: MuteAllView!
  
  var editingTracks = false
  
  // MARK: Overrides
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    do {
      let audioSession = AVAudioSession.sharedInstance()
      try audioSession.setCategory(AVAudioSessionCategoryPlayAndRecord, withOptions: AVAudioSessionCategoryOptions.DefaultToSpeaker)
      try audioSession.setPreferredIOBufferDuration(0.001)
      try AVAudioSession.sharedInstance().setActive(true)
    } catch let error as NSError {
      print("Error starting audio session: \(error.localizedDescription)")
    }
    
    self.trackAccessView.delegate = self
    
    self.collectionView.registerClass(TrackCollectionViewCell.self, forCellWithReuseIdentifier: String(TrackCollectionViewCell))
    self.collectionView.delegate = self
    self.collectionView.dataSource = self
    
    
    self.loopRecordView.parent = self
  }
  
  override func viewDidLayoutSubviews() {
    super.viewDidLayoutSubviews()
    if !(self.collectionView.collectionViewLayout is WaveformCollectionViewLayout) {
      self.setCollectionViewLayoutWithSize(self.collectionView.bounds.size)
    }
  }
  
  override func viewWillTransitionToSize(size: CGSize, withTransitionCoordinator coordinator: UIViewControllerTransitionCoordinator) {
    super.viewWillTransitionToSize(size, withTransitionCoordinator: coordinator)
    let newCollectionViewSize = CGSize(width: size.width, height: size.height - CGFloat(Constants.recordButtonHeight))
    
    coordinator.animateAlongsideTransition({ context in
      self.setCollectionViewLayoutWithSize(newCollectionViewSize)
      }, completion: nil)
  }
  
  override func viewWillAppear(animated: Bool) {
    super.viewWillAppear(animated)
    NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(HomeViewController.onTrackSelected(_:)), name: Constants.notificationTrackSelected, object: nil)
    NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(HomeViewController.onLoopRecordArmed(_:)), name: Constants.notificationLoopRecordArmed, object: nil)
    NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(HomeViewController.onDestroyTrack(_:)), name: Constants.notificationDestroyTrack, object: nil)
  }
  
  override func viewDidDisappear(animated: Bool) {
    super.viewDidDisappear(animated)
    NSNotificationCenter.defaultCenter().removeObserver(self)
  }
  
  override func prefersStatusBarHidden() -> Bool {
    return true
  }
  
  // MARK: Methods
  
  func toggleTrackEditMode() {
    if self.tracks.count > 0 {
      self.editingTracks = !self.editingTracks
      UIView.animateWithDuration(Constants.defaultAnimationDuration, delay: 0, options: [.AllowUserInteraction, .BeginFromCurrentState], animations: {
        for cell in self.visibleCells() {
          cell.editing = self.editingTracks
        }
        }, completion: nil)
    }
  }
  
  
  func createTrack() {
    let newTrack = Track()
    self.collectionView.performBatchUpdates({
      self.tracks.insert(newTrack, atIndex: 0)
      self.collectionView.insertItemsAtIndexPaths([NSIndexPath(forItem: 0, inSection: 0)])
      }, completion: { finished in
        if finished {
          for cell in self.visibleCells() {
            if cell.track == self.tracks.first {
              UIView.animateWithDuration(0.35, delay: 0, options: [.AllowUserInteraction, .BeginFromCurrentState], animations: {
                self.selectCell(cell)
                }, completion: nil)
              break
            }
          }
        }
    })
  }
  
  func onDestroyTrack(notification: NSNotification) {
    if let selectedTrackServiceUUID = notification.userInfo?[Constants.trackServiceUUIDKey] as? String {
      for cell in self.visibleCells() {
        if cell.track?.trackService.uuid == selectedTrackServiceUUID, let indexPath = self.collectionView.indexPathForCell(cell) {
          self.collectionView.performBatchUpdates({
            if let track = cell.track, trackIndex = self.tracks.indexOf(track) {
              if track.trackService.isPlayingLoop {
                track.trackService.removeFromLoopPlayback()
              }
              self.collectionView.deleteItemsAtIndexPaths([indexPath])
              self.tracks.removeAtIndex(trackIndex)
            }
            }, completion: nil)
          break
        }
      }
    }
  }
  
  func onTrackSelected(notification: NSNotification) {
    if let selectedUUID = notification.userInfo?[Constants.trackServiceUUIDKey] as? String {
      for cell in self.visibleCells() {
        if cell.track?.trackService.uuid == selectedUUID {
          if !cell.selectedForLoopRecord {
            self.selectCell(cell)
            self.loopRecordView.setArmed(false)
            for cell in self.visibleCells() {
              cell.track?.trackService.isArmedForLoopRecord = false
            }
          }
          break
        }
      }
    }
  }
  
  func onLoopRecordArmed(notification: NSNotification) {
    for cell in self.visibleCells() {
      if let track = cell.track where track.trackService.isArmedForLoopRecord {
        cell.enabled = true
      } else {
        cell.enabled = false
      }
    }
  }
  
  func onFinishedLoopRecording(notification: NSNotification) {
    
  }
  
  private func visibleCells() -> [TrackCollectionViewCell] {
    return self.collectionView.visibleCells().map({ cell in cell as! TrackCollectionViewCell })
  }
  
  private func setCollectionViewLayoutWithSize(size: CGSize, animated: Bool = false) {
    let layout = TracksCollectionViewLayout(bounds: size)
    self.collectionView.setCollectionViewLayout(layout, animated: animated)
  }
  
  private func selectCell(cell: TrackCollectionViewCell) {
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
    }
  }
  
  // TODO: new track thing that subtly appears when you pull down on collectionview
  private func createNewTrackView() -> UIView {
    let view = UIView()
    
    return view
  }
  
  // MARK: UICollectionViewDataSource
  
  func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
    return self.tracks.count
  }
  
  func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
    let cell = collectionView.dequeueReusableCellWithReuseIdentifier(String(TrackCollectionViewCell), forIndexPath: indexPath) as! TrackCollectionViewCell
    cell.track = self.tracks[indexPath.item]
    
    if !self.didInitialize && self.tracks.count == 1 {
      self.selectCell(cell)
      self.didInitialize = true
    }
    
    cell.selectedForLoopRecord = cell.track == self.selectedTrack
    cell.editing = self.tracks[indexPath.item].waveformView.dimmed
    
    return cell
  }
  
  // MARK: UICollectionViewDelegate
  
  func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
    self.recordView.enabled = true
    self.loopRecordView.enabled = true
    
    if let cell = collectionView.cellForItemAtIndexPath(indexPath) as? TrackCollectionViewCell {
      self.selectCell(cell)
    }
  }
  
  func scrollViewDidEndDragging(scrollView: UIScrollView, willDecelerate decelerate: Bool) {
    if scrollView.contentOffset.y < -50 {
      self.createTrack()
    }
  }
  
  func scrollViewDidScroll(scrollView: UIScrollView) {
    
  }
  
}

