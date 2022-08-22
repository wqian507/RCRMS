//
//  AppDelegate.swift
//  RCRMS
//
//  Created by Wei Qian on 11/10/17.
//  Copyright © 2017 Wei Qian. All rights reserved.
//

import UIKit
import GoogleMaps
import GooglePlaces
import Firebase

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate,CLLocationManagerDelegate{

    var window: UIWindow?
    var currentLocation:String=""
    var locationManager = CLLocationManager()

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        GMSPlacesClient.provideAPIKey("AIzaSyCAms4dPwXNfS0s_qhltt_L9hH5jJ92ZMs")
        GMSServices.provideAPIKey("AIzaSyCAms4dPwXNfS0s_qhltt_L9hH5jJ92ZMs")
        FirebaseApp.configure()
        
        if CLLocationManager.locationServicesEnabled(){
            locationManager.delegate=self
            locationManager.desiredAccuracy = kCLLocationAccuracyBest
            locationManager.startUpdatingLocation()
        }
        
        return true
    }

    func applicationWillResignActive(_ application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }

    func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    }

    func application(_ application: UIApplication, performActionFor shortcutItem: UIApplicationShortcutItem, completionHandler: @escaping (Bool) -> Void) {
    
        let mainStoryboard:UIStoryboard=UIStoryboard(name:"Main",bundle:nil)
        let rootViewController=mainStoryboard.instantiateViewController(withIdentifier: "SWRevealViewController") as! SWRevealViewController
        self.window?.rootViewController=rootViewController
        
        //Here is some problems when first initial the app
        if(currentLocation==""){
            return
        }
        
        if(shortcutItem.type == "Report"){
            let desController=mainStoryboard.instantiateViewController(withIdentifier: "ReportViewController") as! ReportViewController
            let newFrontViewController=UINavigationController.init(rootViewController:desController)
            rootViewController.present(newFrontViewController, animated: true, completion: nil)

            desController.GPS=currentLocation
            var GPSArr=currentLocation.components(separatedBy: " ")
            let coordinate:CLLocationCoordinate2D=CLLocationCoordinate2D.init(latitude: CLLocationDegrees(GPSArr[0])!, longitude: CLLocationDegrees(GPSArr[1])!)
            let geocoder=GMSGeocoder()
            geocoder.reverseGeocodeCoordinate(coordinate) { (response, error) in
                if let location=response?.firstResult() {
                    let lines = location.lines! as [String]
                    desController.road=lines.joined(separator: ", ")
                    desController.tableView.reloadData()
                }
            }
        }
        if(shortcutItem.type == "Mark"){
            let desController=mainStoryboard.instantiateViewController(withIdentifier: "HisViewController") as! HisViewController
            let newFrontViewController=UINavigationController.init(rootViewController:desController)
            rootViewController.present(newFrontViewController, animated: true, completion: nil)
            
            let defaults=UserDefaults.standard
            let date=Date()
            let formate=DateFormatter()
            formate.dateFormat="MM/dd/yyyy"
            
            var locations = defaults.object(forKey: "Location") as? [String] ?? [String]()
            var dates=defaults.object(forKey: "Date") as? [String] ?? [String]()
            var checks=defaults.object(forKey: "Check") as? [Bool] ?? [Bool]()
            
            locations.insert(currentLocation, at: 0)
            dates.insert(formate.string(from: date), at: 0)
            checks.insert(false, at: 0)
            
            defaults.set(locations, forKey: "Location")
            defaults.set(dates, forKey: "Date")
            defaults.set(checks, forKey: "Check")
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        let locValue:CLLocationCoordinate2D = manager.location!.coordinate
        self.currentLocation=String.localizedStringWithFormat("%.6f %.6f", locValue.latitude,locValue.longitude)
    }

}

