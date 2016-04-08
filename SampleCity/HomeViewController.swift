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
  
  private var selectedWaveformView: WaveformView?
  private var tracks = [Track]()
  
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
        self.selectedWaveformView?.enabled = !self.scrollEnabled
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
    
    self.collectionView.registerClass(WaveformCollectionViewCell.self, forCellWithReuseIdentifier: String(WaveformCollectionViewCell))
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
      }, completion: nil)
  }
  
  override func prefersStatusBarHidden() -> Bool {
    return true
  }
  
  // MARK: Methods
  
  func createTrack() {
    let newTrack = Track()
    if let cell = self.collectionView.visibleCells().first as? WaveformCollectionViewCell {
      self.selectedWaveformView = newTrack.waveformView
      self.setTrack(newTrack, forCell: cell)
    }
    
    self.collectionView.performBatchUpdates({
      self.tracks.append(newTrack)
      self.collectionView.insertItemsAtIndexPaths([NSIndexPath(forItem: self.pageControl.numberOfPages - 1, inSection: 0)])
      }, completion: nil)
  }
  
  private func setCollectionViewLayoutWithSize(size: CGSize, animated: Bool = false) {
    let layout = WaveformCollectionViewLayout(bounds: size)
    self.collectionView.setCollectionViewLayout(layout, animated: animated)
  }
  
  private func setTrack(track: Track, forCell cell: WaveformCollectionViewCell) {
    track.trackService.recordDelegate = self.recordView
    track.trackService.loopRecordDelegate = self.loopRecordView
    track.trackService.loopPlaybackDelegate = self.loopPlaybackView
    track.trackService.trackAccessDelegate = self.trackAccessView
    track.trackService.playbackDelegate = track.waveformView
    track.trackService.meterDelegate = track.waveformView
    
    self.recordView.trackService = track.trackService
    self.loopRecordView.trackService = track.trackService
    self.loopPlaybackView.trackService = track.trackService
    
    cell.waveformView = track.waveformView
    cell.waveformView?.trackService = track.trackService
    
    // TODO: change state of loopPlaybackView based on whether current track is playing
  }
  
  private func updateCell(cell: WaveformCollectionViewCell, atIndexPath indexPath: NSIndexPath) {
    if indexPath.item < self.tracks.count {
      let track = self.tracks[indexPath.item]
      self.setTrack(track, forCell: cell)
      self.selectedWaveformView = track.waveformView
      
//      if self.tracks.count == 1 {
//        self.selectedWaveformView?.enabled = true
//      }
      cell.title = nil
    } else {
      cell.waveformView = nil
      cell.title = "CREATE A NEW TRACK, PUNK."
    }
  }
  
  // MARK: UICollectionViewDataSource
  
  func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
    return self.tracks.count + 1
  }
  
  func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
    let cell = collectionView.dequeueReusableCellWithReuseIdentifier(String(WaveformCollectionViewCell), forIndexPath: indexPath) as! WaveformCollectionViewCell
    self.updateCell(cell, atIndexPath: indexPath)
    return cell
  }
  
  // MARK: UICollectionViewDelegate
  
  func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
    self.isSelectingTrack = false
  }
  
  func collectionView(View: UICollectionView, didEndDisplayingCell cell: UICollectionViewCell, forItemAtIndexPath indexPath: NSIndexPath) {
    if let visibleCell = collectionView.visibleCells().first as? WaveformCollectionViewCell, waveformView = visibleCell.waveformView, indexPath = collectionView.indexPathForCell(visibleCell) where !waveformView.enabled {
      self.updateCell(visibleCell, atIndexPath: indexPath)
    }
  }
  
  // MARK: UIScrollViewDelegate
  
  func scrollViewDidEndDecelerating(scrollView: UIScrollView) {
    let pageWidth = self.collectionView.frame.width
    self.pageControl.currentPage = Int(self.collectionView.contentOffset.x / pageWidth);
  }
  
}

