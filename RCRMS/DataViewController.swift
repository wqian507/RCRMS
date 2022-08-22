//
//  DataViewController.swift
//  RCRMS
//
//  Created by Wei Qian on 1/25/18.
//  Copyright © 2018 Wei Qian. All rights reserved.
//

import UIKit
import GoogleMaps
import Firebase

class DataViewController: UIViewController,GMSMapViewDelegate,UITableViewDelegate,UITableViewDataSource {
    
    @IBOutlet weak var UIMapView: UIView!
    @IBOutlet weak var tableview: UITableView!
    
    var locationManager = CLLocationManager()
    var currentLocation: CLLocation?
    var selectedStreet:String=""
    var selectedLocation:CLLocationCoordinate2D?
    var mapView: GMSMapView!
    var zoomLevel: Float = 16.0
    
    var getGPS:String=""
    var road:String=""
    var name:String=""
    var email:String=""
    var rownumber:Int?
    
    var date=Date()
    var formate=DateFormatter()
    var timemate=DateFormatter()
    
    let defaultLocation = CLLocation(latitude: -33.869405, longitude: 151.199)
    
    var titles:Array = [String]()
    var contents:Array = [String]()
    
    var ref: DatabaseReference!
    
    var checks=[Bool]()
    var defaults=UserDefaults.standard
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        NotificationCenter.default.addObserver(self, selector: #selector(DataViewController.keyboardWillShow), name: NSNotification.Name.UIKeyboardWillShow, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(DataViewController.keyboardWillHide), name: NSNotification.Name.UIKeyboardWillHide, object: nil)
        
        titles=["GPS*","Road*","Name*","Email*"]
        contents=["GPS location","Road name","Your name","Email address"]
        
        let sendButton = UIBarButtonItem(title:"Report", style:UIBarButtonItemStyle.plain, target: self, action: #selector(DataViewController.send(sender:)))
        self.navigationItem.rightBarButtonItem=sendButton
        
        // Initialize the location manager.
        locationManager = CLLocationManager()
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.requestAlwaysAuthorization()
        locationManager.distanceFilter = 50
        locationManager.startUpdatingLocation()
        locationManager.delegate = self
        
        var GPSArr=getGPS.components(separatedBy: " ")
        let coordinate:CLLocationCoordinate2D=CLLocationCoordinate2D.init(latitude: CLLocationDegrees(GPSArr[0])!, longitude: CLLocationDegrees(GPSArr[1])!)
        
        // Create a map.
        let camera = GMSCameraPosition.camera(withLatitude: coordinate.latitude,
                                              longitude: coordinate.longitude,
                                              zoom: zoomLevel)
        mapView = GMSMapView.map(withFrame: UIMapView.bounds, camera: camera)
        //mapView.settings.myLocationButton = true
        mapView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        //mapView.isMyLocationEnabled = true
        // Add the map to the view, hide it until we've got a location update.
        let types=defaults.object(forKey: "Type") as? String
        if(types=="1"){
            mapView.mapType=GMSMapViewType.hybrid
        }
        else{
            mapView.mapType=GMSMapViewType.normal
        }
        UIMapView.addSubview(mapView)
        //mapView.isHidden = true
        mapView.delegate=self//add delegate to mapview itself

        // Do any additional setup after loading the view.
        let geocoder=GMSGeocoder()
        geocoder.reverseGeocodeCoordinate(coordinate) { (response, error) in
            if let location=response?.firstResult() {
                //self.selectedLocation=coordinate
                let marker=GMSMarker(position:coordinate)
                let lines = location.lines! as [String]
                self.road=lines.joined(separator: ", ")
                self.tableview.reloadData()
                marker.snippet=lines.joined(separator: ", ")
                marker.infoWindowAnchor = CGPoint(x: 0.5, y: 0)
                marker.accessibilityLabel = "current"
                marker.map=self.mapView
                
                self.mapView.animate(toLocation: coordinate)
                self.mapView.selectedMarker = marker
            }
        }
        checks=self.defaults.object(forKey: "Check") as? [Bool] ?? [Bool]()
    }
    
    @objc func keyboardWillShow(notification: NSNotification) {
        if let keyboardSize = (notification.userInfo?[UIKeyboardFrameBeginUserInfoKey] as? NSValue)?.cgRectValue {
            if self.view.frame.origin.y == 0{
                self.view.frame.origin.y -= keyboardSize.height
            }
        }
    }
    
    @objc func keyboardWillHide(notification: NSNotification) {
        if let keyboardSize = (notification.userInfo?[UIKeyboardFrameBeginUserInfoKey] as? NSValue)?.cgRectValue {
            if self.view.frame.origin.y != 0{
                self.view.frame.origin.y += keyboardSize.height
            }
        }
    }
    
    @objc func send(sender: UIBarButtonItem) {
        getText()
        if(getGPS=="" || road=="" || name=="" || email=="")
        {
            let alertController = UIAlertController(title: "Oops", message: "All information required!", preferredStyle: UIAlertControllerStyle.alert)
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
        else{
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
    
    func sendData()
    {
            formate.dateFormat="MM/dd/yyyy"
            timemate.dateFormat="HH:mm:ss"
            
            var GPSArr=getGPS.components(separatedBy: " ")
            
            ref=Database.database().reference()
            let key=ref.childByAutoId().key
            let comp:Dictionary! = ["lat":GPSArr[0],
                                    "lng":GPSArr[1],
                                    "name":self.name,
                                    "email":self.email,
                                    "date":formate.string(from: date),
                                    "time":timemate.string(from: date)]
            ref.child(key).setValue(comp)
            
            let sentController = UIAlertController(title: "Verification passed!", message: "Report sent", preferredStyle: UIAlertControllerStyle.alert)
            self.present(sentController, animated: true, completion: nil)
            DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 1) {
                self.presentedViewController?.dismiss(animated: false, completion: nil)
    
                self.checks[self.rownumber!]=true
                self.defaults.set(self.checks, forKey: "Check")
                
                self.navigationController?.popViewController(animated: true)
            }
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
    
    //mark the palce after long press
    func mapView(_ mapView: GMSMapView, didLongPressAt coordinate: CLLocationCoordinate2D) {
        self.mapView.clear()
        let geocoder=GMSGeocoder()
        geocoder.reverseGeocodeCoordinate(coordinate) { (response, error) in
            if let location=response?.firstResult() {
                self.selectedLocation=coordinate
                let marker=GMSMarker(position:coordinate)
                let lines = location.lines! as [String]
                self.selectedStreet=lines.joined(separator: ", ")
                marker.snippet=lines.joined(separator: ", ")
                marker.infoWindowAnchor = CGPoint(x: 0.5, y: 0)
                marker.accessibilityLabel = "current"
                marker.map=mapView
                
                self.mapView.animate(toLocation: coordinate)
                self.mapView.selectedMarker = marker
                self.getGPS=String.localizedStringWithFormat("%.6f %.6f", (self.selectedLocation?.latitude)!,(self.selectedLocation?.longitude)!)
                self.road=self.selectedStreet
                self.tableview.reloadData()
            }
        }
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return titles.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "ReportTableViewCell") as! ReportTableViewCell
        cell.lbDataTitle.text!=titles[indexPath.row]
        cell.tfDataContent.placeholder=contents[indexPath.row]
        cell.selectionStyle = .none
        if(indexPath.row==0){
            cell.tfDataContent.text!=self.getGPS
        }
        if(indexPath.row==1){
            cell.tfDataContent.text!=self.road
            print(self.road)
        }
        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        if (section == tableView.numberOfSections - 1) {
            return 1
        }
        return 0
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func getText(){
        let indexGPS=IndexPath(row: 0, section: 0)
        let cellGPS=tableview.cellForRow(at: indexGPS) as! ReportTableViewCell
        getGPS = cellGPS.tfDataContent.text!
        
        let indexRoad=IndexPath(row: 1, section: 0)
        let cellRoad=tableview.cellForRow(at: indexRoad) as! ReportTableViewCell
        road = cellRoad.tfDataContent.text!
        
        let indexName=IndexPath(row: 2, section: 0)
        let cellName=tableview.cellForRow(at: indexName) as! ReportTableViewCell
        name = cellName.tfDataContent.text!
        
        let indexEmail=IndexPath(row: 3, section: 0)
        let cellEmail=tableview.cellForRow(at: indexEmail) as! ReportTableViewCell
        email = cellEmail.tfDataContent.text!
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

// Delegates to handle events for the location manager.
extension DataViewController: CLLocationManagerDelegate {
    
    // Handle incoming location events.
    /*func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        let location: CLLocation = locations.last!
        print("Location: \(location)")
        
        let camera = GMSCameraPosition.camera(withLatitude: location.coordinate.latitude,
                                              longitude: location.coordinate.longitude,
                                              zoom: zoomLevel)
        
        if mapView.isHidden {
            mapView.isHidden = false
            mapView.camera = camera
        } else {
            mapView.animate(to: camera)
        }
        
    }
    
    // Handle authorization for the location manager.
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        switch status {
        case .restricted:
            print("Location access was restricted.")
        case .denied:
            print("User denied access to location.")
            // Display the map using the default location.
            mapView.isHidden = false
        case .notDetermined:
            print("Location status not determined.")
        case .authorizedAlways: fallthrough
        case .authorizedWhenInUse:
            print("Location status is OK.")
        }
    }
    
    // Handle location manager errors.
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        locationManager.stopUpdatingLocation()
        print("Error: \(error)")
    }*/
}
