//
//  ClipsViewController.swift
//  Free Film Camp
//
//  Created by Eric Mentele on 10/6/15.
//  Copyright © 2015 Eric Mentele. All rights reserved.
//

import UIKit
import Photos
import AVKit

class ClipsViewController: UICollectionViewController, UIGestureRecognizerDelegate {

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
    
    // pass back selected video
    var videoAssetToPass: NSURL!
    var initialEntry = true
    
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
        
        // retrieve videos from clips album
        clipsAlbumVideosFetch = PHAsset.fetchAssetsInAssetCollection(clipsAlbum, options: nil)
        
        clipsAlbumVideosFetch.enumerateObjectsUsingBlock { (object, _, _) in
            if let asset = object as? PHAsset {
                self.videos.append(asset)
            }
        }
        // setup gesture recognizer
        longPress = UILongPressGestureRecognizer(target: self, action: "handleLongPress:")
        longPress.minimumPressDuration = 0.5
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
            let alert = UIAlertController(title: "Welcome", message: "Tap image to selct. Tap and hold to play.", preferredStyle: .Alert)
            let action = UIAlertAction(title: "OK", style: .Default, handler: nil)
            alert.addAction(action)
            self.presentViewController(alert, animated: true, completion: nil)
        }
    }
    
    @IBAction func cancelSelection(sender: AnyObject) {
        
        self.dismissViewControllerAnimated(true, completion: nil)
    }

    override func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        
        return clipsAlbum.estimatedAssetCount
    }
    
    override func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier(reuseIdentifier, forIndexPath: indexPath) as! VideoLibraryCell
        cell.backgroundColor = UIColor.blueColor()
        
        if cell.tag != 0 {
            
            manager.cancelImageRequest(PHImageRequestID(cell.tag))
        }
        
        let video = videos[indexPath.row]
        
        cell.tag = Int(manager.requestImageForAsset(video,
            targetSize: CGSize(width: 140, height: 140),
            contentMode: .AspectFill,
            options: nil) { (result, _) -> Void in
                cell.imageView.image = result
        })
        return cell
    }
    
    
    func handleLongPress(gestureRecognizer: UILongPressGestureRecognizer) {
        
        if gestureRecognizer.state != UIGestureRecognizerState.Ended {

            return
        }
        let itemTouched = gestureRecognizer.locationInView(self.collectionView)
        let indexPath = self.collectionView?.indexPathForItemAtPoint(itemTouched)
        var videoPlayer: AVPlayer!
        let video = videos[(indexPath?.row)!]
        manager.requestPlayerItemForVideo(video, options: nil) { (playerItem, info) -> Void in
            videoPlayer = AVPlayer(playerItem: playerItem!)
            self.vpVC.player = videoPlayer
        }
        self.presentViewController(self.vpVC, animated: true, completion: nil)
        
        
    }
    
    
    func handleTap(gestureRecognizer: UITapGestureRecognizer) {
        print("TAP")
        if gestureRecognizer.state != UIGestureRecognizerState.Ended {
            
            return
        }
        let itemTouched = gestureRecognizer.locationInView(self.collectionView)
        let indexPath = self.collectionView?.indexPathForItemAtPoint(itemTouched)
        let video = videos[(indexPath?.row)!]
        manager.requestAVAssetForVideo(video, options: nil) { (videoAsset, audioMix, info) -> Void in
            
            dispatch_async(dispatch_get_main_queue(), { () -> Void in
                
                if (videoAsset?.isKindOfClass(AVURLAsset) != nil) {
                    
                    let url = videoAsset as! AVURLAsset
                    self.videoAssetToPass = url.URL
                    self.performSegueWithIdentifier("clipSelectedSegue", sender: self)
                }
            })
        }
        
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        
        if segue.identifier == "clipSelectedSegue" {
            
            let sceneBuilderVC = segue.destinationViewController as! SceneBuilderViewController
            sceneBuilderVC.selectedVideoAsset = self.videoAssetToPass
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
