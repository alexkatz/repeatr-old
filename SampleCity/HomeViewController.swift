//
//  ViewController.swift
//  SampleCity
//
//  Created by Alexander Katz on 3/19/16.
//  Copyright © 2016 Alexander Katz. All rights reserved.
//

import UIKit
import AVFoundation

class HomeViewController: UIViewController, UICollectionViewDataSource, UICollectionViewDelegate {
  
  private let audioService = AudioService.sharedInstance
  private var selectedWaveformView: WaveformView?
  
  @IBOutlet weak var recordView: RecordView!
  @IBOutlet weak var collectionView: UICollectionView!
  @IBOutlet weak var pageControl: UIPageControl!
  @IBOutlet weak var loopRecordView: LoopRecordView!
  @IBOutlet weak var loopPlaybackView: LoopPlaybackView!
  
  var scrollEnabled = false
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    self.view.backgroundColor = UIColor.blackColor()
    self.recordView.backgroundColor = Constants.redColor
    
    self.audioService.recordDelegate = self.recordView
    self.audioService.loopRecordDelegate = self.loopRecordView
    self.audioService.loopPlaybackDelegate = self.loopPlaybackView
    
    self.pageControl.userInteractionEnabled = false
    self.pageControl.numberOfPages = 1
    self.pageControl.currentPage = 0

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
    }
  }

  override func viewWillTransitionToSize(size: CGSize, withTransitionCoordinator coordinator: UIViewControllerTransitionCoordinator) {
    super.viewWillTransitionToSize(size, withTransitionCoordinator: coordinator)
    let newCollectionViewSize = CGSize(width: size.width, height: size.height - CGFloat(Constants.recordButtonHeight + Constants.homePadding))
    
    coordinator.animateAlongsideTransition({ context in
      self.setCollectionViewLayoutWithSize(newCollectionViewSize)
      self.collectionView.scrollToItemAtIndexPath(NSIndexPath(forItem: self.pageControl.currentPage, inSection: 0), atScrollPosition: .CenteredHorizontally, animated: false)
      }, completion: nil)
  }
  
  override func prefersStatusBarHidden() -> Bool {
    return true
  }
  
  @IBAction func handleMoreButton(sender: AnyObject) {
    self.scrollEnabled = !self.scrollEnabled
    self.collectionView.scrollEnabled = self.scrollEnabled
    self.pageControl.alpha = self.scrollEnabled ? 1 : 0
    self.selectedWaveformView?.setEnabled(!self.scrollEnabled)
    
  }
  
  
  private func setCollectionViewLayoutWithSize(size: CGSize, animated: Bool = false) {
    let layout = WaveformCollectionViewLayout(bounds: size)
    self.collectionView.setCollectionViewLayout(layout, animated: animated)
  }
  
  // MARK: UICollectionViewDataSource
  
  func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
    return 1
  }
  
  func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
    let cell = collectionView.dequeueReusableCellWithReuseIdentifier(String(WaveformCollectionViewCell), forIndexPath: indexPath) as! WaveformCollectionViewCell
    self.audioService.playbackDelegate = cell.waveformView
    self.audioService.meterDelegate = cell.waveformView
    self.selectedWaveformView = cell.waveformView
    return cell
  }
  
  // MARK: UIScrollViewDelegate
  
  func scrollViewDidEndDecelerating(scrollView: UIScrollView) {
    let pageWidth = self.collectionView.frame.width
    self.pageControl.currentPage = Int(self.collectionView.contentOffset.x / pageWidth);
  }
  
}

