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
    } catch {
      print("Error starting audio session")
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
      
      }, completion: { finished in
        //        if let cell = self.collectionView.visibleCells().first as? TrackCollectionViewCell, indexPath = self.collectionView.indexPathForCell(cell) {
        //          self.updateCell(cell, atIndexPath: indexPath)
        //        }
    })
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
  
  func setTrackEditModeEnabled(enabled: Bool, animated: Bool = true) {
    if self.tracks.count == 0 {
      return
    }
    
    self.editingTracks = enabled
    
    let setCellsEditing = {
      for cell in self.visibleCells() {
        cell.editing = enabled
      }
    }
    
    if animated {
      UIView.animateWithDuration(Constants.defaultAnimationDuration, delay: 0, options: [.AllowUserInteraction, .BeginFromCurrentState], animations: {
        setCellsEditing()
        }, completion: nil)
    } else {
      setCellsEditing()
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
              self.selectCell(cell)
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
        visibleCell.track?.trackService.isArmedForLoopRecord = false
        self.loopRecordView.setArmed(false)
      }
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
    
    cell.selectedForLoopRecord = cell.track == self.selectedTrack
    
    if !self.didInitialize && self.tracks.count == 1 {
      self.selectCell(cell)
      self.didInitialize = true
    }
    
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

