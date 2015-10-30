//
//  MovieBuilderViewController.swift
//  Free Film Camp
//
//  Created by Eric Mentele on 10/5/15.
//  Copyright © 2015 Craig Swanson. All rights reserved.
//

import UIKit
import Photos
import AVKit


class MovieBuilderViewController: UIViewController {
    
    @IBOutlet weak var savingProgress: UIActivityIndicatorView!
    @IBOutlet weak var headshot: UIImageView!
    
    var videoPlayer: AVPlayer!
    var vpVC = AVPlayerViewController()
    var previewQueue = [AVPlayerItem]()

    override func viewDidLoad() {
        super.viewDidLoad()
        MediaController.sharedMediaController.prepareMovie(false)
        self.navigationItem.hidesBackButton = true
    }
    
    override func viewWillAppear(animated: Bool) {
        self.navigationController?.setNavigationBarHidden(false, animated: false)
        self.navigationController?.navigationBar.setBackgroundImage(UIImage(named: "Movie"), forBarMetrics: .Default)
    }
    
    override func viewWillDisappear(animated: Bool) {
        MediaController.sharedMediaController.moviePreview = nil 
    }
    
    
    @IBAction func swipeBack(sender: AnyObject) {
        self.navigationController?.popViewControllerAnimated(true)
    }
    
    @IBAction func addHeadshot(sender: AnyObject) {
        
    }

    @IBAction func addMusic(sender: AnyObject) {
        
        
    }
    
    @IBAction func makeMovie(sender: AnyObject) {
        self.vpVC.player = nil
        self.videoPlayer = nil
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "saveCompleted:", name: "saveComplete", object: nil)
        self.savingProgress.alpha = 1
        self.savingProgress.startAnimating()
        self.view.alpha = 0.6
        MediaController.sharedMediaController.prepareMovie(true)
    }
    
    func saveCompleted(notification: NSNotification) {
        self.savingProgress.stopAnimating()
        self.savingProgress.alpha = 0
        self.view.alpha = 1
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }
    
    @IBAction func preview(sender: AnyObject) {
        if MediaController.sharedMediaController.moviePreview != nil {
            self.videoPlayer = AVPlayer(playerItem: MediaController.sharedMediaController.moviePreview)
            self.vpVC.player = videoPlayer
            self.presentViewController(self.vpVC, animated: true, completion: nil)
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
