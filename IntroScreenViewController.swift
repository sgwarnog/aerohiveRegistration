//
//  IntroScreenViewController.swift
//  visitorWiFi
//
//  Created by joseff harris on 05/07/2016.
//  Copyright © 2016 joseff harris. All rights reserved.
//

import UIKit

class IntroScreenViewController: UIViewController {
        
    @IBOutlet weak var goToRegistrationScreen: UIButton!
    override func viewDidLoad() {
        super.viewDidLoad()
                // Do any additional setup after loading the view.
        
        let defaults = NSUserDefaults.standardUserDefaults()

        if(!NSUserDefaults.standardUserDefaults().boolForKey("firstlaunch1.0")){
            //Put any code here and it will be executed only once.
            print("Is a first launch")
            NSUserDefaults.standardUserDefaults().setBool(true, forKey: "firstlaunch1.0")
            
            defaults.setBool(false, forKey: "successfulTest")
            defaults.setObject("VHM Id", forKey: "VHMID")
            defaults.setObject("Client ID", forKey: "clientID")
            defaults.setObject("Client secret", forKey: "clientSecret")
            defaults.setObject("Redirect URL", forKey: "clientRedirectURI")
            defaults.setObject("Access Token", forKey: "accessToken")
            defaults.setObject("Datacenter URL", forKey: "datacenterURL")
            defaults.setObject("Group ID", forKey: "groupID")
            
            goToRegistrationScreen.enabled = false
        }
        
        if defaults.boolForKey("successfulTest") == true {
            goToRegistrationScreen.enabled = true
        } else {
            goToRegistrationScreen.enabled = false
        }

    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

}
