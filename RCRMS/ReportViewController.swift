//
//  ReportViewController.swift
//  RCRMS
//
//  Created by Wei Qian on 11/11/17.
//  Copyright © 2017 Wei Qian. All rights reserved.
//

import UIKit
import GoogleMaps
import Firebase
import FirebaseDatabase
import CoreLocation
import SystemConfiguration

class ReportViewController: UIViewController,UITableViewDelegate,UITableViewDataSource,CLLocationManagerDelegate{
    
    @IBOutlet weak var tableView: UITableView!
    
    var titles:Array = [String]()
    var contents:Array = [String]()
    
    var GPS:String=""
    var lat:String=""
    var lng:String=""
    var road:String=""
    var name:String=""
    var email:String=""
    
    var date=Date()
    var formate=DateFormatter()
    var timemate=DateFormatter()
    
    var connect:Bool=false
    
    var ref: DatabaseReference!

    var locationManager = CLLocationManager()
    
    var handle: AuthStateDidChangeListenerHandle?

    override func viewDidLoad() {
        super.viewDidLoad()
        
        titles=["GPS*","Road*","Name*","Email*"]
        contents=["GPS location","Road name","Your name","Email address"]
        
        let newBackButton = UIBarButtonItem(title: "Back", style: UIBarButtonItemStyle.plain, target: self, action: #selector(ReportViewController.back(sender:)))
        self.navigationItem.title="Report"
        let sendButton = UIBarButtonItem(title:"Send", style:UIBarButtonItemStyle.plain, target: self, action: #selector(ReportViewController.send(sender:)))
        self.navigationItem.leftBarButtonItem = newBackButton
        self.navigationItem.rightBarButtonItem=sendButton
    
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        // [START auth_listener]
        handle = Auth.auth().addStateDidChangeListener { (auth, user) in
            // [START_EXCLUDE]
            //self.setTitleDisplay(user)
            //self.tableView.reloadData()
            // [END_EXCLUDE]
        }
        // [END auth_listener]
    }
    
    
    @objc func back(sender: UIBarButtonItem) {
        let storyBoard : UIStoryboard = UIStoryboard(name: "Main", bundle:nil)
        let resultViewController = storyBoard.instantiateViewController(withIdentifier: "SWRevealViewController") as! SWRevealViewController
        self.present(resultViewController, animated:true, completion:nil)

    }
    
    @objc func send(sender: UIBarButtonItem) {
        getText()
        if(GPS=="" || road=="" || name=="" || email=="")
        {
            let alertController = UIAlertController(title: "Oops", message: "All information required!", preferredStyle: UIAlertControllerStyle.alert)
            let okAction = UIAlertAction(title: "OK", style: UIAlertActionStyle.default) {
                (result : UIAlertAction) -> Void in
                print("OK")
            }
            alertController.addAction(okAction)
            self.present(alertController, animated: true, completion: nil)
        }
        else if !isInternetAvailable(){
            let alertController = UIAlertController(title: "Network Error", message: "Please check your network!", preferredStyle: UIAlertControllerStyle.alert)
            let okAction = UIAlertAction(title: "OK", style: UIAlertActionStyle.default) {
                (result : UIAlertAction) -> Void in
                print("OK")
            }
            alertController.addAction(okAction)
            self.present(alertController, animated: true, completion: nil)
        }
        else if !isValid(email){
            let alertController = UIAlertController(title: "Email Error", message: "Wrong email format!", preferredStyle: UIAlertControllerStyle.alert)
            let okAction = UIAlertAction(title: "OK", style: UIAlertActionStyle.default) {
                (result : UIAlertAction) -> Void in
                print("OK")
            }
            alertController.addAction(okAction)
            self.present(alertController, animated: true, completion: nil)
        }
        else
        {
            /*var code:String=""
            
            let alert=UIAlertController(title: "Validate Your Email", message: email, preferredStyle: .alert)
            alert.addTextField{
                (text:UITextField!)->Void in text.placeholder="Enter the number you received"
            }
            let action=UIAlertAction(title: "Confirm", style: .default) { (_) in
                code = alert.textFields!.first!.text!
                if code=="1"{
                    self.sendData()
                }
                else{
                    let sentController = UIAlertController(title: "Verification failed", message: "Incorrect verification code!", preferredStyle: UIAlertControllerStyle.alert)
                    self.present(sentController, animated: true, completion: nil)
                    DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 3) {
                        self.presentedViewController?.dismiss(animated: false, completion: nil)
                    }1
                }
            }
            let cancel=UIAlertAction(title: "Cancel", style: .cancel) { (action: UIAlertAction!) in
                print("Cancel")
            }
            alert.addAction(action)
            alert.addAction(cancel)
            self.present(alert, animated: true)*/
            
            let username=email
            let password="Password"
            
            Auth.auth().signIn(withEmail: username, password: password, completion: { (user, error) in
                if error != nil{
                    print("Email signIn succeed")
                    self.sendData()
                }
                else{
                    print("Email signIn failed")
                }
            })
            
        }
    }
    
    //authentication before sending data
    func sendData(){
        formate.dateFormat="MM/dd/yyyy"
        timemate.dateFormat="HH:mm:ss"
        
        ref=Database.database().reference()
        let key=ref.childByAutoId().key
        let comp:Dictionary! = ["lat":self.lat,
                                "lng":self.lng,
                                "name":self.name,
                                "email":self.email,
                                "date":formate.string(from: date),
                                "time":timemate.string(from: date)]
        ref.child(key).setValue(comp)
        
        let sentController = UIAlertController(title: "Verification passed!", message: "Report sent", preferredStyle: UIAlertControllerStyle.alert)
        self.present(sentController, animated: true, completion: nil)
        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 2) {
            self.presentedViewController?.dismiss(animated: false, completion: nil)
            
            let storyBoard : UIStoryboard = UIStoryboard(name: "Main", bundle:nil)
            let resultViewController = storyBoard.instantiateViewController(withIdentifier: "SWRevealViewController") as! SWRevealViewController
            self.present(resultViewController, animated:true, completion:nil)
        }
    }
    
    //reload tableview
    override func viewDidAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.tableView.reloadData()
    }
    
    /// Validate email string
    ///
    /// - parameter email: A String that rappresent an email address
    ///
    /// - returns: A Boolean value indicating whether an email is valid.
    func isValid(_ email: String) -> Bool {
        let emailRegEx = "(?:[a-z0-9!#$%\\&'*+/=?\\^_`{|}~-]+(?:\\.[a-z0-9!#$%\\&'*+/=?\\^_`{|}"+"~-]+)*|\"(?:[\\x01-\\x08\\x0b\\x0c\\x0e-\\x1f\\x21\\x23-\\x5b\\x5d-\\"+"x7f]|\\\\[\\x01-\\x09\\x0b\\x0c\\x0e-\\x7f])*\")@(?:(?:[a-z0-9](?:[a-"+"z0-9-]*[a-z0-9])?\\.)+[a-z0-9](?:[a-z0-9-]*[a-z0-9])?|\\[(?:(?:25[0-5"+"]|2[0-4][0-9]|[01]?[0-9][0-9]?)\\.){3}(?:25[0-5]|2[0-4][0-9]|[01]?[0-"+"9][0-9]?|[a-z0-9-]*[a-z0-9]:(?:[\\x01-\\x08\\x0b\\x0c\\x0e-\\x1f\\x21"+"-\\x5a\\x53-\\x7f]|\\\\[\\x01-\\x09\\x0b\\x0c\\x0e-\\x7f])+)\\])"
        
        let emailTest = NSPredicate(format:"SELF MATCHES[c] %@", emailRegEx)
        return emailTest.evaluate(with: email)
    }
    
    //check network connection
    func isInternetAvailable() -> Bool
    {
        var zeroAddress = sockaddr_in()
        zeroAddress.sin_len = UInt8(MemoryLayout.size(ofValue: zeroAddress))
        zeroAddress.sin_family = sa_family_t(AF_INET)
        
        let defaultRouteReachability = withUnsafePointer(to: &zeroAddress) {
            $0.withMemoryRebound(to: sockaddr.self, capacity: 1) {zeroSockAddress in
                SCNetworkReachabilityCreateWithAddress(nil, zeroSockAddress)
            }
        }
        
        var flags = SCNetworkReachabilityFlags()
        if !SCNetworkReachabilityGetFlags(defaultRouteReachability!, &flags) {
            return false
        }
        let isReachable = flags.contains(.reachable)
        let needsConnection = flags.contains(.connectionRequired)
        return (isReachable && !needsConnection)
    }

    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return titles.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "ReportTableViewCell") as! ReportTableViewCell
        cell.lbTitle.text!=titles[indexPath.row]
        cell.tfContent.placeholder=contents[indexPath.row]
        cell.selectionStyle = .none
        if(indexPath.row==0){
            cell.tfContent.text!=GPS
            cell.accessoryType=UITableViewCellAccessoryType.disclosureIndicator
        }
        if(indexPath.row==1){
            cell.tfContent.text!=self.road
        }
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if indexPath.row==0{
            let mainStoryboard:UIStoryboard=UIStoryboard(name:"Main",bundle:nil)
            let desController=mainStoryboard.instantiateViewController(withIdentifier: "LocateViewController") as! LocateViewController
            self.navigationController?.pushViewController(desController, animated: true)
            desController.GPS=self.GPS
        }
    }
    
    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        if (section == tableView.numberOfSections - 1) {
            return 1
        }
        return 0
    }
    
    func getText(){
        let indexGPS=IndexPath(row: 0, section: 0)
        let cellGPS=tableView.cellForRow(at: indexGPS) as! ReportTableViewCell
        GPS = cellGPS.tfContent.text!
        
        let indexRoad=IndexPath(row: 1, section: 0)
        let cellRoad=tableView.cellForRow(at: indexRoad) as! ReportTableViewCell
        road = cellRoad.tfContent.text!
        
        let indexName=IndexPath(row: 2, section: 0)
        let cellName=tableView.cellForRow(at: indexName) as! ReportTableViewCell
        name = cellName.tfContent.text!
        
        let indexEmail=IndexPath(row: 3, section: 0)
        let cellEmail=tableView.cellForRow(at: indexEmail) as! ReportTableViewCell
        email = cellEmail.tfContent.text!
    }
    
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */
}
