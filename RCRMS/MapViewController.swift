//
//  ViewController.swift
//  RCRMS
//
//  Created by Wei Qian on 11/10/17.
//  Copyright © 2017 Wei Qian. All rights reserved.
//

import UIKit
import GoogleMaps
import GooglePlaces
import SystemConfiguration

class MapViewController: UIViewController,GMSMapViewDelegate,UICollectionViewDataSource,UICollectionViewDelegate,UICollectionViewDelegateFlowLayout {
    
    @IBOutlet weak var btnMenu: UIBarButtonItem!
    
    @IBOutlet weak var btType: UIButton!
    
    @IBAction func btChange(_ sender: UIButton) {
        var types=defaults.object(forKey: "Type") as? String
        if(types=="1"){
            mapView.mapType=GMSMapViewType.normal
            types="0"
        }
        else{
            mapView.mapType=GMSMapViewType.hybrid
            types="1"
        }
        defaults.set(types, forKey: "Type")
    }
    
    var locationManager = CLLocationManager()
    var currentLocation: CLLocation?
    var mapView: GMSMapView!
    var placesClient: GMSPlacesClient!
    var zoomLevel: Float = 16.0
    var selectedStreet:String=""
    var selectedLocation:CLLocationCoordinate2D?
    var offlineLocation:String?
    
    var defaults=UserDefaults.standard
    
    // An array to hold the list of likely places.
    var likelyPlaces: [GMSPlace] = []
    
    // The currently selected place.
    var selectedPlace: GMSPlace?
    
    // A default location to use when location permission is not granted.
    let defaultLocation = CLLocation(latitude: 46.491793, longitude: -84.363877)
    
    // Update the map once the user has made their selection.
    @IBAction func unwindToMain(segue: UIStoryboardSegue) {
        // Clear the map.
        mapView.clear()
        
        // Add a marker to the map.
        if selectedPlace != nil {
            let marker = GMSMarker(position: (self.selectedPlace?.coordinate)!)
            marker.title = selectedPlace?.name
            marker.snippet = selectedPlace?.formattedAddress
            marker.map = mapView
        }
        
        listLikelyPlaces()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        collectionView.dataSource=self
        collectionView.delegate=self
        collectionView.register(CellSetting.self, forCellWithReuseIdentifier: cellId)
        
        btnMenu.target=revealViewController()
        btnMenu.action=#selector(SWRevealViewController.revealToggle(_:))
        
        // Initialize the location manager.
        locationManager = CLLocationManager()
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.requestAlwaysAuthorization()
        locationManager.distanceFilter = 50
        locationManager.startUpdatingLocation()
        locationManager.delegate = self
        
        placesClient = GMSPlacesClient.shared()
        
        //3D Touch
        let Item1=UIApplicationShortcutItem.init(type: "Report", localizedTitle: "Report road", localizedSubtitle: nil, icon: UIApplicationShortcutIcon.init(type: UIApplicationShortcutIconType.compose), userInfo: nil)
        let Item2=UIApplicationShortcutItem.init(type: "Mark", localizedTitle: "Mark location", localizedSubtitle: nil, icon: UIApplicationShortcutIcon.init(type: UIApplicationShortcutIconType.markLocation), userInfo: nil)
        let Item3=UIApplicationShortcutItem.init(type: "Share", localizedTitle: "Share RCRMS", localizedSubtitle: nil, icon: UIApplicationShortcutIcon.init(type: UIApplicationShortcutIconType.share), userInfo: nil)
        
        UIApplication.shared.shortcutItems=[Item1,Item2,Item3]
        
        // Create a map.
        let camera = GMSCameraPosition.camera(withLatitude: defaultLocation.coordinate.latitude,
                                              longitude: defaultLocation.coordinate.longitude,
                                              zoom: zoomLevel)
        mapView = GMSMapView.map(withFrame: view.bounds, camera: camera)
        mapView.settings.myLocationButton = true
        mapView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        mapView.isMyLocationEnabled = true
        // Add the map to the view, hide it until we've got a location update.
        view.addSubview(mapView)
        btType.layer.shadowColor=UIColor.gray.cgColor
        view.addSubview(btType)
        
        let types=defaults.object(forKey: "Type") as? String
        if(types=="1"){
            mapView.mapType=GMSMapViewType.hybrid
        }
        
        mapView.isHidden = true
        mapView.delegate=self//add delegate to mapview itself
        
        listLikelyPlaces()
        
        if isInternetAvailable(){
            //print("true")
        }
        else{
            //print("false")
            let alertController = UIAlertController(title: "Network Unavailable", message: "In offline mode, you can only mark your GPS location!", preferredStyle: UIAlertControllerStyle.alert)
            let okAction = UIAlertAction(title: "OK", style: UIAlertActionStyle.default) {
                (result : UIAlertAction) -> Void in
                print("OK")
            }
            alertController.addAction(okAction)
            self.present(alertController, animated: true, completion: nil)
        }
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

    
    // Populate the array with the list of likely places.
    func listLikelyPlaces() {
        // Clean up from previous sessions.
        likelyPlaces.removeAll()
        
        placesClient.currentPlace(callback: { (placeLikelihoods, error) -> Void in
            if let error = error {
                // TODO: Handle the error.
                print("Current Place error: \(error.localizedDescription)")
                return
            }
            
            // Get likely places and add to the list.
            if let likelihoodList = placeLikelihoods {
                for likelihood in likelihoodList.likelihoods {
                    let place = likelihood.place
                    self.likelyPlaces.append(place)
                }
            }
        })
    }
    
    // Prepare the segue.
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "segueToSelect" {
            if let nextViewController = segue.destination as? PlacesViewController {
                nextViewController.likelyPlaces = likelyPlaces
            }
        }
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
            }
        }
        handleMenu()
    }
    
    let blackView=UIView()
    
    //create a bottom sheet
    let collectionView:UICollectionView={
        let layout=UICollectionViewFlowLayout()
        let cv=UICollectionView(frame: .zero, collectionViewLayout: layout)
        cv.backgroundColor=UIColor.white
        return cv
    }()
    //cell in bottom sheet
    let cellId="cellId"
    let cellHeight=50
    
    let settings:[Setting]={
        return [Setting(name:"Quick Report",imgName:"comment"),
                Setting(name:"Quick Mark",imgName:"mark"),
                Setting(name:"Cancel",imgName:"delete")]
    }()
    
    //hidden the blackgroung
    func handleMenu(){
        if let window = UIApplication.shared.keyWindow{
            blackView.backgroundColor=UIColor(white:0,alpha:0)
            blackView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(handleDismiss)))
            window.addSubview(blackView)
            window.addSubview(collectionView)
            
            let height:CGFloat=CGFloat(settings.count*cellHeight)//height may be changed accroding to the screen size
            let y=window.frame.height-height
            collectionView.frame=CGRect(x: 0, y: window.frame.height, width: window.frame.width, height: height)
            
            blackView.frame=window.frame
            blackView.alpha=0
            
            //EaseOut animation
            UIView.animate(withDuration: 0.5, delay: 0, usingSpringWithDamping: 1, initialSpringVelocity: 1, options: .curveEaseOut, animations: {
                self.blackView.alpha=1
                self.collectionView.frame=CGRect(x: 0, y: y, width: self.collectionView.frame.width, height: self.collectionView.frame.height)
            }, completion: nil)
        }
    }
    
    @objc func handleDismiss(){
        UIView.animate(withDuration: 0.5) {
            self.blackView.alpha=0
            if let window=UIApplication.shared.keyWindow{
                self.collectionView.frame=CGRect(x: 0, y: window.frame.height, width: self.collectionView.frame.width, height: self.collectionView.frame.height)
            }
        }
        self.mapView.clear()
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let cell:CellSetting=collectionView.cellForItem(at: indexPath) as! CellSetting
        if(cell.lbName.text!=="Cancel"){
            handleDismiss()
        }
        if(cell.lbName.text!=="Quick Report"){
            handleDismiss()
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
            let revealViewController:SWRevealViewController=self.revealViewController()
            let mainStoryboard:UIStoryboard=UIStoryboard(name:"Main",bundle:nil)
            let desController=mainStoryboard.instantiateViewController(withIdentifier: "ReportViewController") as! ReportViewController
            let newFrontViewController=UINavigationController.init(rootViewController:desController)
            revealViewController.present(newFrontViewController, animated: true, completion: nil)
            desController.road=self.selectedStreet
            desController.lat=String.localizedStringWithFormat("%.6f", (self.selectedLocation?.latitude)!)
            desController.lng=String.localizedStringWithFormat("%.6f", (self.selectedLocation?.longitude)!)
            desController.GPS=String.localizedStringWithFormat("%.6f %.6f", (self.selectedLocation?.latitude)!,(self.selectedLocation?.longitude)!)
        }
        if(cell.lbName.text!=="Quick Mark"){
            handleDismiss()
            
            let revealViewController:SWRevealViewController=self.revealViewController()
            let mainStoryboard:UIStoryboard=UIStoryboard(name:"Main",bundle:nil)
            let desController=mainStoryboard.instantiateViewController(withIdentifier: "HisViewController") as! HisViewController
            let newFrontViewController=UINavigationController.init(rootViewController:desController)
            revealViewController.present(newFrontViewController, animated: true, completion: nil)
            //desController.insert(String.localizedStringWithFormat("%.6f %.6f", (self.selectedLocation?.latitude)!,(self.selectedLocation?.longitude)!))
            
            let defaults=UserDefaults.standard
            let date=Date()
            let formate=DateFormatter()
            formate.dateFormat="MM/dd/yyyy"
            
            var locations = defaults.object(forKey: "Location") as? [String] ?? [String]()
            var dates=defaults.object(forKey: "Date") as? [String] ?? [String]()
            var checks=defaults.object(forKey: "Check") as? [Bool] ?? [Bool]()
            
            if !isInternetAvailable(){
                locations.insert(offlineLocation!, at: 0)
                dates.insert(formate.string(from: date), at: 0)
                checks.insert(false, at: 0)
                
                defaults.set(locations, forKey: "Location")
                defaults.set(dates, forKey: "Date")
                defaults.set(checks, forKey: "Check")
                return
            }
            
            locations.insert(String.localizedStringWithFormat("%.6f %.6f", (self.selectedLocation?.latitude)!,(self.selectedLocation?.longitude)!), at: 0)
            dates.insert(formate.string(from: date), at: 0)
            checks.insert(false, at: 0)
            
            defaults.set(locations, forKey: "Location")
            defaults.set(dates, forKey: "Date")
            defaults.set(checks, forKey: "Check")
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return settings.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
            let cell=collectionView.dequeueReusableCell(withReuseIdentifier: cellId, for: indexPath) as! CellSetting
            let setting=settings[indexPath.item]
            cell.setting=setting
            return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: collectionView.frame.width, height: CGFloat(cellHeight))
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return 0
    }
    
}

class Setting:NSObject{
    let name:String
    let imgName:String
    init(name:String,imgName:String){
        self.name=name
        self.imgName=imgName
    }
}

// Delegates to handle events for the location manager.
extension MapViewController: CLLocationManagerDelegate {
    
    // Handle incoming location events.
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        let location: CLLocation = locations.last!
        self.offlineLocation=String.localizedStringWithFormat("%.6f %.6f", location.coordinate.latitude,location.coordinate.longitude)
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
        
        listLikelyPlaces()
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
    }
}
