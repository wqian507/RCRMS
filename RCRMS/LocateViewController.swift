//
//  LocateViewController.swift
//  RCRMS
//
//  Created by Wei Qian on 2/4/18.
//  Copyright © 2018 Wei Qian. All rights reserved.
//

import UIKit
import GoogleMaps

class LocateViewController: UIViewController,GMSMapViewDelegate {

    var locationManager = CLLocationManager()
    var mapView: GMSMapView!
    var zoomLevel: Float = 17.0
    var marker:GMSMarker!
    var centerMapCoordinate:CLLocationCoordinate2D!
    var GPS:String=""
    var selectedStreet:String=""
    
    var defaults=UserDefaults.standard
    
    // A default location to use when location permission is not granted.
    let defaultLocation = CLLocation(latitude: -33.869405, longitude: 151.199)
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.navigationItem.title="Choose Location"
        let okButton = UIBarButtonItem(title:"OK", style:UIBarButtonItemStyle.plain, target: self, action: #selector(LocateViewController.update(sender:)))
        self.navigationItem.rightBarButtonItem=okButton

        // Initialize the location manager.
        locationManager = CLLocationManager()
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.requestAlwaysAuthorization()
        locationManager.distanceFilter = 50
        locationManager.startUpdatingLocation()
        locationManager.delegate = self
        
        //var GPSArr=getGPS.components(separatedBy: " ")
        //let coordinate:CLLocationCoordinate2D=CLLocationCoordinate2D.init(latitude: CLLocationDegrees(GPSArr[0])!, longitude: CLLocationDegrees(GPSArr[1])!)
        
        // Create a map.
        let camera = GMSCameraPosition.camera(withLatitude: defaultLocation.coordinate.latitude,
                                              longitude: defaultLocation.coordinate.longitude,
                                              zoom: zoomLevel)
        mapView = GMSMapView.map(withFrame: view.bounds, camera: camera)
        mapView.settings.myLocationButton = true
        mapView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        mapView.isMyLocationEnabled = true
        // Add the map to the view, hide it until we've got a location update.
        let types=defaults.object(forKey: "Type") as? String
        if(types=="1"){
            mapView.mapType=GMSMapViewType.hybrid
        }
        if(types=="0"){
            mapView.mapType=GMSMapViewType.normal
        }
        view.addSubview(mapView)
        mapView.isHidden = true
        mapView.delegate=self//add delegate to mapview itself
        
        if !GPS.isEmpty{
            var GPSArr=GPS.components(separatedBy: " ")
            let convertCoordinate:CLLocationCoordinate2D=CLLocationCoordinate2D.init(latitude: CLLocationDegrees(GPSArr[0])!, longitude: CLLocationDegrees(GPSArr[1])!)
            placeMarkerOnCenter(centerMapCoordinate: convertCoordinate)
        }
    }
    
    @objc func update(sender: UIBarButtonItem) {
        //self.navigationController?.popViewController(animated: true)
        performSegue(withIdentifier: "passData", sender: self)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        let desController=segue.destination as! ReportViewController
        desController.GPS=String.localizedStringWithFormat("%.6f %.6f", (centerMapCoordinate.latitude),(centerMapCoordinate.longitude))
        desController.lat=String.localizedStringWithFormat("%.6f", centerMapCoordinate.latitude)
        desController.lng=String.localizedStringWithFormat("%.6", centerMapCoordinate.longitude)
        desController.road=self.selectedStreet
    }
    
    func mapView(_ mapView: GMSMapView, didChange position: GMSCameraPosition) {
        let latitude = mapView.camera.target.latitude
        let longitude = mapView.camera.target.longitude
        centerMapCoordinate = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
        self.placeMarkerOnCenter(centerMapCoordinate:centerMapCoordinate)
    }
    
    func placeMarkerOnCenter(centerMapCoordinate:CLLocationCoordinate2D) {
        if marker == nil {
            marker = GMSMarker()
        }
        marker.position = centerMapCoordinate
        marker.map = self.mapView
        
        let geocoder=GMSGeocoder()
        geocoder.reverseGeocodeCoordinate(centerMapCoordinate) { (response, error) in
            if let location=response?.firstResult() {
                let lines = location.lines! as [String]
                self.selectedStreet=lines.joined(separator: ", ")
            }
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
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

extension LocateViewController: CLLocationManagerDelegate {
    // Handle incoming location events.
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if !GPS.isEmpty{
            var GPSArr=GPS.components(separatedBy: " ")
            let convertCoordinate:CLLocationCoordinate2D=CLLocationCoordinate2D.init(latitude: CLLocationDegrees(GPSArr[0])!, longitude: CLLocationDegrees(GPSArr[1])!)
            let camera=GMSCameraPosition.camera(withLatitude: convertCoordinate.latitude,
                                                longitude: convertCoordinate.longitude,
                                                zoom: zoomLevel)
            if mapView.isHidden {
                mapView.isHidden = false
                mapView.camera = camera
            } else {
                mapView.animate(to: camera)
            }
        }
        else{
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
