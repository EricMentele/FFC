//  assisted by http://swiftiostutorials.com/tutorial-custom-tabbar-storyboard/
//  SelectionViewController.swift
//  Free Film Camp
//
//  Created by Eric Mentele on 11/1/15.
//  Copyright © 2015 Eric Mentele. All rights reserved.
//

import UIKit

class SelectionViewController: UIViewController {
    var currentViewController: UIViewController!
    @IBOutlet weak var viewsView: UIView!
    @IBOutlet var buttons: Array<UIButton>!
    let segueIDS = ["introVC","scene1VC", "scene2VC", "scene3VC", "movieVC"]
    var lastSegue: String!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        if self.buttons.count > 0 {
            self.performSegueWithIdentifier("scene1VC", sender: self.buttons[1])
        }
        self.navigationController?.navigationBarHidden = true
    }
    
    // MARK: View lifecycle for subviews
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        currentViewController.viewWillAppear(animated)
    }
    
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        currentViewController.viewWillDisappear(animated)
    }
    
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        currentViewController.viewDidAppear(animated)
    }
    
    
    override func viewDidDisappear(animated: Bool) {
        super.viewDidDisappear(animated)
        currentViewController.viewDidDisappear(animated)
    }
    
    // MARK: Gesture navigation
    @IBAction func swipedLeft(sender: AnyObject) {
        if self.lastSegue != segueIDS.last {
            let segueToPerform = (segueIDS.indexOf(self.lastSegue)! + 1)
            self.performSegueWithIdentifier(segueIDS[segueToPerform], sender: self.buttons[segueToPerform])
        }
    }
    
    @IBAction func swipedRight(sender: AnyObject) {
        if self.lastSegue != segueIDS.first {
            let segueToPerform = (segueIDS.indexOf(self.lastSegue)! - 1)
            self.performSegueWithIdentifier(segueIDS[segueToPerform], sender: self.buttons[segueToPerform])
        }
    }
    
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if self.segueIDS.contains(segue.identifier!) {
            self.lastSegue = segue.identifier
            for button in self.buttons {
                button.selected = false
            }
            let senderButton = sender as! UIButton
            senderButton.selected = true
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
