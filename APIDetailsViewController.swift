//
//  APIDetailsViewController.swift
//  visitorWiFi
//
//  Created by joseff harris on 05/07/2016.
//  Copyright © 2016 joseff harris. All rights reserved.
//

import UIKit

class APIDetailsViewController: UIViewController, UITextFieldDelegate {

//Mark @IB outlets and actions
    
    @IBOutlet weak var VHMID: UITextField!
    @IBOutlet weak var clientID: UITextField!
    @IBOutlet weak var clientSecret: UITextField!
    @IBOutlet weak var redirectURL: UITextField!
    @IBOutlet weak var accessToken: UITextField!
    @IBOutlet weak var datacenterURL: UITextField!
    @IBOutlet weak var groupID: UITextField!
    @IBOutlet weak var done: UIButton!

    @IBAction func done(sender: AnyObject) {
        
        let defaults = NSUserDefaults.standardUserDefaults()

        defaults.setBool(true, forKey: "successfulTest")
        defaults.setObject("\(VHMID.text!)", forKey: "VHMID")
        defaults.setObject("\(clientID.text!)", forKey: "clientID")
        defaults.setObject("\(clientSecret.text!)", forKey: "clientSecret")
        defaults.setObject("\(redirectURL.text!)", forKey: "clientRedirectURI")
        defaults.setObject("\(accessToken.text!)", forKey: "accessToken")
        defaults.setObject("\(datacenterURL.text!)", forKey: "datacenterURL")
        defaults.setObject("\(groupID.text!)", forKey: "groupID")
        
        
    }
    
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    
    @IBAction func Test(sender: UIButton) {
        
        let button = sender
        submitTestRequestFunction(button)
    }
    
    //Outlet for ScrollView - allows for view to be raised so that keyboard does not obscure text fields
    
    @IBOutlet weak var ScrollView: UIScrollView!
      
//Mark methods
    
    func textFieldShouldReturn(textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
    
    func textFieldDidBeginEditing(textField: UITextField) {
        
        ScrollView.setContentOffset(CGPointMake(0, 130), animated: true)
    }
    
    func textFieldDidEndEditing(textField: UITextField) {
        ScrollView.setContentOffset(CGPointMake(0, 0), animated: true)
    }
    
    //Function to submit the request for a list of devices and check the status of the response.
        func submitTestRequestFunction(buttonPressed: UIButton) {
            let headers = [
                "authorization": "Bearer \(accessToken.text!)",
                "x-ah-api-client-id": "\(clientID.text!)",
                "x-ah-api-client-secret": "\(clientSecret.text!)",
                "x-ah-api-client-redirect-uri": "\(redirectURL.text!)",
                "content-type": "application/json"
            ]
            print(VHMID.text!)
            let request = NSMutableURLRequest(URL:NSURL(string: "https://\(datacenterURL.text!)/xapi/v1/monitor/devices?ownerId=\(VHMID.text!)")!, cachePolicy:.UseProtocolCachePolicy, timeoutInterval: 5.0)
            request.allHTTPHeaderFields = headers
            request.HTTPMethod = "GET"

            //END
            
            // start the NSURLSession and then the data task.
            let session = NSURLSession.sharedSession()
            
            let dataTask = session.dataTaskWithRequest(request, completionHandler:{(data, response, error) -> Void in
                
                //extract status code  from response part or if there was no response show alert then return.
                guard let httpResponse = response as? NSHTTPURLResponse else {
                    //If there is no response show alert
                    dispatch_async(dispatch_get_main_queue()) {
                        let noResponseAlert = UIAlertController(title: "No response from server", message: "please check connectivity and try again", preferredStyle: UIAlertControllerStyle.Alert)
                        noResponseAlert.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.Default, handler: nil))
                        self.presentViewController(noResponseAlert, animated: true, completion: nil)
                    }
                    
                    return
                }
                
                //There was a response so...
                
                //parse JSON of data part - note the seperate error part is always nil and the error information is found within the data part.
                let dataPartParsed = parseJSON(data!)
                
                //Take actions based on the status code of the response
                if case httpResponse.statusCode = 200 {
                    
                    //Go back to main execution queue
                    dispatch_async(dispatch_get_main_queue()) {
                        
                        //Response has been received so stop the activity indicator animation
                        self.activityIndicator.stopAnimating()
                        
                        //Display an alert with the status and message
                        
                        let alert = UIAlertController(title: "200", message: "success", preferredStyle: UIAlertControllerStyle.Alert)
                        alert.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.Default, handler: nil))
                        self.presentViewController(alert, animated: true, completion: nil)
                        self.done.enabled = true

                        
                    }
                    
                } else {
                    
                    dispatch_async(dispatch_get_main_queue()) {
                        
                        //Response has been received so stop the activity indicator animation
                        self.activityIndicator.stopAnimating()
                        
                        //Display an alert with the error status and message
                        let errorStatus = (dataPartParsed! ["error"]!["status"]!)!
                        let errorCode = (dataPartParsed! ["error"]!["code"]!)!
                        let errorAlert = UIAlertController(title: "error \(errorStatus)", message: "\(errorCode)", preferredStyle: UIAlertControllerStyle.Alert)
                        errorAlert.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.Default, handler: nil))
                        self.presentViewController(errorAlert, animated: true, completion: nil)
                    }
                }
                
                }
            )
            
            dataTask.resume()
            self.activityIndicator.startAnimating()
            
            return        
        }
        
    
//Mark Boiler plate
    override func viewDidLoad() {
        super.viewDidLoad()
        activityIndicator.stopAnimating()
        done.enabled = false
        let defaults = NSUserDefaults.standardUserDefaults()
        VHMID.text! = (defaults.objectForKey("VHMID") as! String)
        clientID.text = defaults.objectForKey("clientID") as? String
        clientSecret.text = defaults.objectForKey("clientSecret") as? String
        redirectURL.text = defaults.objectForKey("clientRedirectURI") as? String
        accessToken.text = defaults.objectForKey("accessToken") as? String
        datacenterURL.text = defaults.objectForKey("datacenterURL") as? String
        groupID.text = defaults.objectForKey("groupID") as? String
        
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
}
