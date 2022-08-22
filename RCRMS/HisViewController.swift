//
//  HisViewController.swift
//  RCRMS
//
//  Created by Wei Qian on 12/1/17.
//  Copyright © 2017 Wei Qian. All rights reserved.
//

import UIKit
import GoogleMaps
import SystemConfiguration

class HisViewController: UIViewController,UITableViewDelegate,UITableViewDataSource,CLLocationManagerDelegate {
    
    @IBOutlet weak var tableview: UITableView!
    
    var locations = [String]()
    var dates = [String]()
    var checks=[Bool]()
    var currentLocation:String?
    var locationManager = CLLocationManager()
    var date=Date()
    var formate=DateFormatter()
    
    var defaults=UserDefaults.standard
    
    override func viewDidLoad() {
        super.viewDidLoad()
        let newBackButton = UIBarButtonItem(title: "Back", style: UIBarButtonItemStyle.plain, target: self, action: #selector(HisViewController.back(sender:)))
        let addButton = UIBarButtonItem(title:"Add", style:UIBarButtonItemStyle.plain, target: self, action: #selector(HisViewController.add(sender:)))
        self.navigationItem.title="Mark History"
        self.navigationItem.leftBarButtonItem = newBackButton
        self.navigationItem.rightBarButtonItem = addButton
        // Do any additional setup after loading the view.
        
        if CLLocationManager.locationServicesEnabled(){
         locationManager.delegate=self
         locationManager.desiredAccuracy = kCLLocationAccuracyBest
         locationManager.startUpdatingLocation()
         }
        
        //clear userdefault data
        /*let domain = Bundle.main.bundleIdentifier!
        UserDefaults.standard.removePersistentDomain(forName: domain)
        UserDefaults.standard.synchronize()
        print(Array(UserDefaults.standard.dictionaryRepresentation().keys).count)*/
        
        //retrive data locally
        locations = defaults.object(forKey: "Location") as? [String] ?? [String]()
        dates=defaults.object(forKey: "Date") as? [String] ?? [String]()
        checks=defaults.object(forKey: "Check") as? [Bool] ?? [Bool]()
    }
    
    //reload tableview
    override func viewDidAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.tableview.reloadData()
    }
    
    @objc func back(sender: UIBarButtonItem) {
        let storyBoard : UIStoryboard = UIStoryboard(name: "Main", bundle:nil)
        let resultViewController = storyBoard.instantiateViewController(withIdentifier: "SWRevealViewController") as! SWRevealViewController
        self.present(resultViewController, animated:true, completion:nil)
    }
    
    @objc func add(sender:UIBarButtonItem){
        let alert=UIAlertController(title: "Current GPS location", message: nil, preferredStyle: .alert)
        alert.addTextField{
            (content) in content.text=self.currentLocation
        }
        let action=UIAlertAction(title: "Add", style: .default) { (_) in
            guard let contents = alert.textFields?.first?.text else {return}
            print(contents)
            self.insert(contents)
        }
        let cancel=UIAlertAction(title: "Cancel", style: .cancel) { (action: UIAlertAction!) in
            print("Cancel")
        }
        alert.addAction(action)
        alert.addAction(cancel)
        self.present(alert, animated: true)
    }
    
    func insert(_ content:String){
        if content==""{
            return
        }
        
        let index=0
        locations.insert(content, at: index)
        formate.dateFormat="MM/dd/yyyy"
        dates.insert(formate.string(from: date), at: index)
        checks.insert(false, at: index)
        
        //save loacl data
        defaults.set(locations, forKey: "Location")
        defaults.set(dates, forKey: "Date")
        defaults.set(checks, forKey: "Check")
        
        //tableview.reloadData()
        let indexPath=IndexPath(row: index, section: 0)
        tableview.insertRows(at: [indexPath], with: .left)
        //tableview.cellForRow(at: indexPath)?.accessoryType=UITableViewCellAccessoryType.none
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        let locValue:CLLocationCoordinate2D = manager.location!.coordinate
        self.currentLocation=String.localizedStringWithFormat("%.6f %.6f", locValue.latitude,locValue.longitude)
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return locations.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        //retrive data locally
        locations = defaults.object(forKey: "Location") as? [String] ?? [String]()
        dates=defaults.object(forKey: "Date") as? [String] ?? [String]()
        checks=defaults.object(forKey: "Check") as? [Bool] ?? [Bool]()
        
        var cell = tableView.dequeueReusableCell(withIdentifier: "reuseIdentifier")
        if cell == nil {
            cell = UITableViewCell(style: .value1, reuseIdentifier: "reuseIdentifier")
        }
        cell?.textLabel?.text=locations[indexPath.row]
        cell?.detailTextLabel?.text=dates[indexPath.row]
        if checks[indexPath.row]==false{
            cell?.accessoryType=UITableViewCellAccessoryType.none
        }
        else{
            cell?.accessoryType=UITableViewCellAccessoryType.checkmark
        }
        return cell!
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        guard editingStyle == .delete else{return}
        locations.remove(at: indexPath.row)
        dates.remove(at: indexPath.row)
        checks.remove(at: indexPath.row)
        
        defaults.set(locations, forKey: "Location")
        defaults.set(dates, forKey: "Date")
        defaults.set(checks, forKey: "Check")
        
        tableview.deleteRows(at: [indexPath], with: .automatic)
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return self.tableview.frame.size.height/10
    }
    
    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        if (section == tableView.numberOfSections - 1) {
            return 1
        }
        return 0
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if !isInternetAvailable(){
            let alertController = UIAlertController(title: "Network Error", message: "Please check your network!", preferredStyle: UIAlertControllerStyle.alert)
            let okAction = UIAlertAction(title: "OK", style: UIAlertActionStyle.default) {
                (result : UIAlertAction) -> Void in
                print("OK")
            }
            alertController.addAction(okAction)
            self.present(alertController, animated: true, completion: nil)
            return
        }
        
        let mainStoryboard:UIStoryboard=UIStoryboard(name:"Main",bundle:nil)
        let desController=mainStoryboard.instantiateViewController(withIdentifier: "DataViewController") as! DataViewController
        desController.getGPS=locations[indexPath.row]
        desController.rownumber=indexPath.row
        self.navigationController?.pushViewController(desController, animated: true)
    }
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
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
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
