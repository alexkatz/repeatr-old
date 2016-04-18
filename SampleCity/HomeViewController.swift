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
  
  private var selectedCell: TrackCollectionViewCell?
  private var tracks = [Track]()
  private var didInitialize = false
  
  @IBOutlet weak var recordView: RecordView!
  @IBOutlet weak var collectionView: UICollectionView!
  @IBOutlet weak var pageControl: UIPageControl!
  @IBOutlet weak var loopRecordView: LoopRecordView!
  @IBOutlet weak var loopPlaybackView: LoopPlaybackView!
  @IBOutlet weak var trackAccessView: TrackAccessView!
  
  var scrollEnabled = false {
    didSet {
      self.collectionView.scrollEnabled = self.scrollEnabled
      UIView.animateWithDuration(Constants.defaultAnimationDuration, delay: 0, options: [.AllowUserInteraction, .BeginFromCurrentState], animations: {
        self.pageControl.alpha = self.scrollEnabled ? 1 : 0
        self.selectedCell?.active = !self.scrollEnabled
        }, completion: nil)
    }
  }
  
  var isSelectingTrack = false {
    didSet {
      self.pageControl.numberOfPages = self.tracks.count + 1
      if !self.isSelectingTrack && self.pageControl.currentPage == self.pageControl.numberOfPages - 1 {
        self.createTrack()
      }
      self.scrollEnabled = self.isSelectingTrack
      self.recordView.enabled = !self.isSelectingTrack
      self.loopRecordView.enabled = !self.isSelectingTrack
    }
  }
  
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
    
    self.tracks.append(Track())
    
    self.pageControl.userInteractionEnabled = false
    self.pageControl.numberOfPages = self.tracks.count + 1
    self.pageControl.currentPage = 0
    
    self.trackAccessView.delegate = self
    
    self.collectionView.registerClass(TrackCollectionViewCell.self, forCellWithReuseIdentifier: String(TrackCollectionViewCell))
    self.collectionView.delegate = self
    self.collectionView.dataSource = self
    self.scrollEnabled = false
  }
  
  override func viewDidLayoutSubviews() {
    super.viewDidLayoutSubviews()
    if !(self.collectionView.collectionViewLayout is WaveformCollectionViewLayout) {
      self.setCollectionViewLayoutWithSize(self.collectionView.bounds.size)
      self.collectionView.scrollToItemAtIndexPath(NSIndexPath(forItem: self.pageControl.currentPage, inSection: 0), atScrollPosition: .CenteredHorizontally, animated: false)
      self.scrollEnabled = false
    }
  }
  
  override func viewWillTransitionToSize(size: CGSize, withTransitionCoordinator coordinator: UIViewControllerTransitionCoordinator) {
    super.viewWillTransitionToSize(size, withTransitionCoordinator: coordinator)
    let newCollectionViewSize = CGSize(width: size.width, height: size.height - CGFloat(Constants.recordButtonHeight))
    
    coordinator.animateAlongsideTransition({ context in
      self.setCollectionViewLayoutWithSize(newCollectionViewSize)
      self.collectionView.scrollToItemAtIndexPath(NSIndexPath(forItem: self.pageControl.currentPage, inSection: 0), atScrollPosition: .CenteredHorizontally, animated: false)
      }, completion: { finished in
        if let cell = self.collectionView.visibleCells().first as? TrackCollectionViewCell, indexPath = self.collectionView.indexPathForCell(cell) {
          self.updateCell(cell, atIndexPath: indexPath)
        }
    })
  }
  
  override func prefersStatusBarHidden() -> Bool {
    return true
  }
  
  // MARK: Methods
  
  func createTrack() {
    let newTrack = Track()
    if let cell = self.collectionView.visibleCells().first as? TrackCollectionViewCell {
      self.selectedCell = cell
    }
    
    self.collectionView.performBatchUpdates({
      self.tracks.append(newTrack)
      self.collectionView.insertItemsAtIndexPaths([NSIndexPath(forItem: self.pageControl.numberOfPages - 1, inSection: 0)])
      }, completion: { finished in
        if finished {
          if let selectedCell = self.selectedCell {
            self.setTrack(newTrack, forCell: selectedCell)
          }
        }
    })
  }
  
  private func setCollectionViewLayoutWithSize(size: CGSize, animated: Bool = false) {
    let layout = WaveformCollectionViewLayout(bounds: size)
    self.collectionView.setCollectionViewLayout(layout, animated: animated)
  }
  
  private func setTrack(track: Track, forCell cell: TrackCollectionViewCell) {
    track.trackService.recordDelegate = self.recordView
    track.trackService.loopRecordDelegate = self.loopRecordView
    track.trackService.loopPlaybackDelegate = self.loopPlaybackView
    track.trackService.trackAccessDelegate = self.trackAccessView
    track.trackService.playbackDelegate = track.waveformView
    track.trackService.meterDelegate = track.waveformView
    
    self.recordView.trackService = track.trackService
    self.loopRecordView.trackService = track.trackService
    self.loopPlaybackView.trackService = track.trackService
    
    cell.track = track
  }
  
  private func updateCell(cell: TrackCollectionViewCell, atIndexPath indexPath: NSIndexPath) {
    if indexPath.item < self.tracks.count {
      let track = self.tracks[indexPath.item]
      self.setTrack(track, forCell: cell)
      self.selectedCell = cell
      
      if self.tracks.count == 1 && !self.didInitialize {
        self.selectedCell?.active = true
        self.didInitialize = true
      }
      cell.title = nil
    } else {
      cell.track = nil
      cell.title = "CREATE A NEW TRACK, PUNK."
    }
  }
  
  // MARK: UICollectionViewDataSource
  
  func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
    return self.tracks.count + 1
  }
  
  func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
    let cell = collectionView.dequeueReusableCellWithReuseIdentifier(String(TrackCollectionViewCell), forIndexPath: indexPath) as! TrackCollectionViewCell
    self.updateCell(cell, atIndexPath: indexPath)
    return cell
  }
  
  // MARK: UICollectionViewDelegate
  
  func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
    self.isSelectingTrack = false
  }
  
  func collectionView(View: UICollectionView, didEndDisplayingCell cell: UICollectionViewCell, forItemAtIndexPath indexPath: NSIndexPath) {
    if let visibleCell = collectionView.visibleCells().first as? TrackCollectionViewCell, indexPath = collectionView.indexPathForCell(visibleCell) where !visibleCell.active && visibleCell != self.selectedCell {
      self.updateCell(visibleCell, atIndexPath: indexPath)
    }
  }
  
  // MARK: UIScrollViewDelegate
  
  func scrollViewDidEndDecelerating(scrollView: UIScrollView) {
    let pageWidth = self.collectionView.frame.width
    self.pageControl.currentPage = Int(self.collectionView.contentOffset.x / pageWidth);
  }
  
}

