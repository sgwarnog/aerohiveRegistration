//
//  ViewController.swift
//  popover
//
//  Created by joseff harris on 11/06/2016.
//  Copyright © 2016 joseff harris. All rights reserved.
//

import UIKit

var email: String?
var mobileNumber: String?
var password: String?
var ssid: Array<String>?
var visitorSSID: String?

let defaults = NSUserDefaults.standardUserDefaults()
let VHMID = (defaults.objectForKey("VHMID") as! String)
let clientID = defaults.objectForKey("clientID") as! String
let clientSecret = defaults.objectForKey("clientSecret") as! String
let redirectURL = defaults.objectForKey("clientRedirectURI")! as! String
let accessToken = defaults.objectForKey("accessToken") as! String
let datacenterURL = defaults.objectForKey("datacenterURL") as! String
let groupID = defaults.objectForKey("groupID") as! String

class ViewController: UIViewController, UITextFieldDelegate {
  
//Mark - Constants and variables
    
    //set up headers for the http request in an array. These remain the same for all requests.
    
    let headers = [
        "authorization": "Bearer \(accessToken)",
        "x-ah-api-client-id": "\(clientID)",
        "x-ah-api-client-secret": "\(clientSecret)",
        "x-ah-api-client-redirect-uri": "\(redirectURL)",
        "content-type": "application/json"
    ]

    
    // set up the URL for the http request. This is the same for each time the http request is made for credentials.
    let request = NSMutableURLRequest(URL:NSURL(string: "https://\(datacenterURL)/xapi/v1/identity/credentials?ownerId=\(VHMID)")!, cachePolicy:.UseProtocolCachePolicy, timeoutInterval: 5.0)
    
//Mark - @IB actions and outlets
    
    //Text field for guests's emailaddress
    @IBOutlet weak var guestEmailAddress: UITextField!

    //Text field for guest's mobile number
    @IBOutlet weak var guestMobileNumber: UITextField!
   
    //Label to display the visitor's ssid
    @IBOutlet weak var ssidReturned: UILabel!

    //Label to display the visitor's password
    @IBOutlet weak var visitorPassword: UILabel!
    
    //Outlet for ScrollView - allows for view to be raised so that keyboard does not obscure text fields
    @IBOutlet weak var ScrollView: UIScrollView!
    
    //Outlet to allow the register button properties to be changed.
    @IBOutlet weak var registerButton: UIButton!

    //Button to register and request credential.
    @IBAction func registerButton(sender: UIButton) {
        
        //Saving information on button so it can be passed to the main function and used when displaying popover.
        let button = sender

        //Get the visitor's email and mobile number details and put them in variables ready to pass to the main function.
        email = guestEmailAddress.text!
        let guestNumber = guestMobileNumber.text!
        
        //Reformat the number to remove leading zero and add country code
        
        let visitorPhoneNumberReformatted = reformatPhoneNumber(guestNumber)
        
        
        //Call the main function to submit details to retrieve credentials
        submitCredentialRequestFunction(button, visitorEmail: email, visitorMobileNumber: visitorPhoneNumberReformatted)
    }
    
    //Outlet to allow the clear button properties to be changed
    @IBOutlet weak var clearButton: UIButton!
    
    //Action to clear the visitor password, email address and mobile number
    @IBAction func clearFields(sender: AnyObject) {
        visitorPassword.text = ""
        ssidReturned.text = ""
        guestEmailAddress.text = ""
        guestMobileNumber.text = ""
        self.clearButton.enabled = false
       let imageClearEnabled = UIImage(named: "clear un enabled") as UIImage?
        self.clearButton.setImage(imageClearEnabled, forState: .Normal)
        self.registerButton.enabled = true
       let imageRegisterDisabled = UIImage(named: "register enabled") as UIImage?
        self.registerButton.setImage(imageRegisterDisabled, forState: .Normal)

    }
    
    //Outlet to allow control of the activity indicator
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!

//Mark - Methods
    
    func adjustForKeyboard(notification: NSNotification) {
        ScrollView.setContentOffset(CGPointMake(0, 0), animated: true)
        return
    }
    
    
    func textFieldShouldReturn(textField: UITextField) -> Bool {
        ScrollView.setContentOffset(CGPointMake(0, 0), animated: true)
        textField.resignFirstResponder()
        return true
    }
    
    func textFieldDidBeginEditing(textField: UITextField) {
        ScrollView.setContentOffset(CGPointMake(0, 140), animated: true)
    }
    
/*    func reformatMobilePhoneNumber () {
        
    }
*/
    //Function to parse the JSON returned by the request
    func parseJSON(data: NSData) -> [String:AnyObject]? {
        do{
            return try NSJSONSerialization.JSONObjectWithData(data, options: []) as? Dictionary
        } catch {
            print ("JSON Error: \(error)")
            return nil
        }
    }
    
//Mark - THIS IS IT! 
    
    //Function to submit the request for a credential using the information entered by the user and return the results.
    func submitCredentialRequestFunction(buttonPressed: UIButton, visitorEmail: String?, visitorMobileNumber: String?) {
        
        // Set up the parameters for this request. Except for "policy" these will change for each user and be supplied in the UI.
        let jsonString = "{\"deliverMethod\":\"EMAIL_AND_SMS\",\"policy\":\"PERSONAL\",\"groupId\":\(groupID),\"email\":\"\((visitorEmail)!)\",\"phone\":\"\((visitorMobileNumber)!)\"}"
        
        // Encode these parameters as JSON and save to the HTTP body of the request
        request.HTTPBody = jsonString.dataUsingEncoding(NSUTF8StringEncoding, allowLossyConversion: true)
        
        // Finish the set up of the request by adding the headers and the body (parameters)
        request.HTTPMethod = "POST"
        request.allHTTPHeaderFields = headers
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
            let dataPartParsed = self.parseJSON(data!)
            
            //Take actions based on the status code of the response
            if case httpResponse.statusCode = 200 {
                
                //Get password from response
                password = (dataPartParsed! ["data"]!["password"]!)! as? String
                ssid = (dataPartParsed! ["data"]!["ssid"]!)! as? Array<String>
                visitorSSID = ssid![0]
                
                //Go back to main execution queue
                dispatch_async(dispatch_get_main_queue()) {
                    
                    //Response has been received so stop the activity indicator animation
                    self.activityIndicator.stopAnimating()
                    
                    //Present the password information and change states and images of clear and register buttons
                    self.visitorPassword.text = password
                    self.ssidReturned.text = visitorSSID!
                    self.clearButton.enabled = true
                    let imageClearEnabled = UIImage(named: "clear enabled") as UIImage?
                    self.clearButton.setImage(imageClearEnabled, forState: .Normal)
                    self.registerButton.enabled = false
                    let imageRegisterDisabled = UIImage(named: "register un enabled") as UIImage?
                    self.registerButton.setImage(imageRegisterDisabled, forState: .Normal)

                }
                
                } else {
                
                dispatch_async(dispatch_get_main_queue()) {
                
                //Response has been received so stop the activity indicator animation
                self.activityIndicator.stopAnimating()
                
                //Display an alert with the error status and message
                let errorStatus = (dataPartParsed! ["error"]!["status"]!)!
                let errorMessage = (dataPartParsed! ["error"]!["message"]!)!
                let errorAlert = UIAlertController(title: "error \(errorStatus)", message: "\(errorMessage)", preferredStyle: UIAlertControllerStyle.Alert)
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
    
//Mark - boiler plate
    
    override func viewDidLoad() {
        super.viewDidLoad()
        let notificationCenter = NSNotificationCenter.defaultCenter()
        notificationCenter.addObserver(self, selector: #selector(adjustForKeyboard), name: UIKeyboardWillHideNotification, object: nil)
        
        //Set states of buttons and stop activity indicator from running
        registerButton.enabled = true
        clearButton.enabled = false
        activityIndicator.stopAnimating()
        
        //Set attributes of borders
        let borderColor = UIColor(red: 0.2, green: 0.3, blue: 0.4, alpha: 1.0).CGColor
        guestEmailAddress.layer.borderColor = borderColor
        guestEmailAddress.layer.borderWidth = 1.0
        guestEmailAddress.layer.cornerRadius = 0.0
        
        guestMobileNumber.layer.borderColor = borderColor
        guestMobileNumber.layer.borderWidth = 1.0
        guestMobileNumber.layer.cornerRadius = 0.0
        
/*        let borderColor2 = UIColor(red: 0.2, green: 0.3, blue: 0.4, alpha: 0.3).CGColor
        visitorPassword.layer.borderColor = borderColor2
        visitorPassword.layer.borderWidth = 1.0
        visitorPassword.layer.cornerRadius = 0.0
        
        ssidReturned.layer.borderColor = borderColor2
        ssidReturned.layer.borderWidth = 1.0
        ssidReturned.layer.cornerRadius = 0.0
        
*/
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
}

