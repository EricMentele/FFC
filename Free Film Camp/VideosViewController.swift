//
//  VideosViewController.swift
//  Free Film Camp
//
//  Created by Eric Mentele on 10/6/15.
//  Copyright © 2015 Craig Swanson. All rights reserved.
//

import UIKit
import Photos
import AVKit

class VideosViewController: UICollectionViewController, UIGestureRecognizerDelegate {

    let library = PHPhotoLibrary.sharedPhotoLibrary()
    let manager = PHImageManager.defaultManager()
    let vpVC = AVPlayerViewController()
    let defaults = NSUserDefaults()

    // fetch albums and assets
    let fetchOptions = PHFetchOptions()
    let albumTitle = "Free Film Camp Clips"
    var clipsAlbumFetch: PHFetchResult!
    var clipsAlbumVideosFetch: PHFetchResult!
    var clipsAlbum: PHAssetCollection!
    let reuseIdentifier = "ClipCell"
    var videos = [PHAsset]()
    
    // handle interaction
    var longPress: UILongPressGestureRecognizer!
    var tap: UITapGestureRecognizer!
    var timer: NSTimer!
    var longItem: CGPoint!
    
    // handle segue based on presenting VC
    var segueID: String!
    
    // pass back selected video and image
    var videoAssetToPass: NSURL!
    var initialEntry = true
    var images = [UIImage]()
    var videoImageToPass: UIImage!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // retrieve or creat clips album
        fetchOptions.predicate = NSPredicate(format: "title = %@", albumTitle)
        clipsAlbumFetch = PHAssetCollection.fetchAssetCollectionsWithType(.Album, subtype: .Any, options: fetchOptions)
        clipsAlbum = clipsAlbumFetch.firstObject as! PHAssetCollection

        if let _: AnyObject = clipsAlbumFetch.firstObject {
                        print("Free Film Camp Clips exists")
        } else {
            
            library.performChanges({ () -> Void in
                PHAssetCollectionChangeRequest.creationRequestForAssetCollectionWithTitle(albumTitle)
                }) { (success: Bool, error: NSError?) -> Void in
                    if !success {
                        print(error!.localizedDescription)
                    }
            }
            
        }
        
        // setup to retrieve videos from clips album
        clipsAlbumVideosFetch = PHAsset.fetchAssetsInAssetCollection(clipsAlbum, options: nil)
        
        // setup gesture recognizer
        longPress = UILongPressGestureRecognizer(target: self, action: "handleLongPress:")
        longPress.minimumPressDuration = 0.3
        longPress.delegate = self
        longPress.delaysTouchesBegan = true
        self.collectionView?.addGestureRecognizer(longPress)
        tap = UITapGestureRecognizer(target: self, action: "handleTap:")
        tap.delegate = self
        self.collectionView?.addGestureRecognizer(tap)
        // tell user how to use
        if defaults.objectForKey("initialEntry") != nil{
            initialEntry = (defaults.objectForKey("initialEntry") as? Bool)!
        }
        
        if initialEntry {
            initialEntry = false
            defaults.setObject(initialEntry, forKey: "initialEntry")
            defaults.synchronize()
            let alert = UIAlertController(title: "Welcome", message: "Tap image to select. Tap and hold to play.", preferredStyle: .Alert)
            let action = UIAlertAction(title: "OK", style: .Default, handler: nil)
            alert.addAction(action)
            self.presentViewController(alert, animated: true, completion: nil)
        }
    }
    
    override func viewWillAppear(animated: Bool) {
        
        self.navigationController?.navigationBarHidden = false
        clipsAlbumVideosFetch.enumerateObjectsUsingBlock { (object, _, _) in
            if let asset = object as? PHAsset {
                self.videos.append(asset)
            }
        }
        
    }
    
    
    
    @IBAction func cameraUnwind(unwindSegue: UIStoryboardSegue) {
        
        
    }
    
    // MARK: Collection view delegate methods
    override func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        
        return clipsAlbum.estimatedAssetCount + 1
    }
    
    override func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        
        if indexPath.item == 0 {
            
            let cameraCell = collectionView.dequeueReusableCellWithReuseIdentifier("cameraCell", forIndexPath: indexPath)
            return cameraCell
        } else {
            
            let cell = collectionView.dequeueReusableCellWithReuseIdentifier(reuseIdentifier, forIndexPath: indexPath) as! VideoLibraryCell
            
            if cell.tag != 0 {
                
                manager.cancelImageRequest(PHImageRequestID(cell.tag))
            }
            
            let video = videos[indexPath.row - 1]
            
            cell.tag = Int(manager.requestImageForAsset(video,
                targetSize: CGSize(width: 215, height: 136),
                contentMode: .AspectFill,
                options: nil) { (result, _) -> Void in
                    cell.imageView.image = result
                    self.images.append(result!)
                })
            
            return cell
        }
        
    }
    
    // MARK: Media selection methods
    func handleLongPress(gestureRecognizer: UILongPressGestureRecognizer) {
        
        if gestureRecognizer.state == UIGestureRecognizerState.Began {
            
            self.longItem = gestureRecognizer.locationInView(self.collectionView)
            timer = NSTimer.scheduledTimerWithTimeInterval(0.1, target: self, selector: "endLongPress:", userInfo: nil, repeats: false)
            
        } else if gestureRecognizer.state == UIGestureRecognizerState.Ended {
            
            self.timer.invalidate()
            self.timer = nil
            self.longItem = nil
        }
    }
    
    func endLongPress(timer: NSTimer!) {
        
        let indexPath = self.collectionView?.indexPathForItemAtPoint(self.longItem)
        var videoPlayer: AVPlayer!
        if indexPath!.row > 0 {
            let video = videos[(indexPath?.row)! - 1]
            manager.requestPlayerItemForVideo(video, options: nil) { (playerItem, info) -> Void in
                
                dispatch_async(dispatch_get_main_queue(), { () -> Void in
                    
                    videoPlayer = AVPlayer(playerItem: playerItem!)
                    self.vpVC.player = videoPlayer
                    self.presentViewController(self.vpVC, animated: true, completion: nil)
                })
            }
        }
    }
    
    
    func handleTap(gestureRecognizer: UITapGestureRecognizer) {
        print("TAP")
        if gestureRecognizer.state != UIGestureRecognizerState.Ended {
            
            return
        }
        let itemTouched = gestureRecognizer.locationInView(self.collectionView)
        let indexPath = self.collectionView?.indexPathForItemAtPoint(itemTouched)
        if indexPath!.row > 0 {
            let video = videos[(indexPath?.row)! - 1]
            manager.requestAVAssetForVideo(video, options: nil) { (videoAsset, audioMix, info) -> Void in
                
                dispatch_async(dispatch_get_main_queue(), { () -> Void in
                    
                    if (videoAsset?.isKindOfClass(AVURLAsset) != nil) {
                        
                        let url = videoAsset as! AVURLAsset
                        self.videoAssetToPass = url.URL
                        self.videoImageToPass = self.images[(indexPath?.row)! - 1]
                        self.performSegueWithIdentifier(self.segueID, sender: self)
                    }
                })
            }
        }
    }
    
    // MARK: Segue methods
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        
        if segue.identifier == "s1ClipSelectedSegue" {
            
            let scene1BuilderVC = segue.destinationViewController as! FirstSceneViewController
            scene1BuilderVC.selectedVideoAsset = self.videoAssetToPass
            scene1BuilderVC.selectedVideoImage = self.videoImageToPass
        } else if segue.identifier == "s2ClipSelectedSegue" {
            
            let scene2BuilderVC = segue.destinationViewController as! SecondSceneViewController
            scene2BuilderVC.selectedVideoAsset = self.videoAssetToPass
            scene2BuilderVC.selectedVideoImage = self.videoImageToPass
        } else if segue.identifier == "s3ClipSelectedSegue" {
            
            let scene3BuilderVC = segue.destinationViewController as! ThirdSceneViewController
            scene3BuilderVC.selectedVideoAsset = self.videoAssetToPass
            scene3BuilderVC.selectedVideoImage = self.videoImageToPass
        } else if segue.identifier == "pickingShot" {
            
            let cameraVC = segue.destinationViewController as! CameraViewController
            cameraVC.pickingShot = true
        }

    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}