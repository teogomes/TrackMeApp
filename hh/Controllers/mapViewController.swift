//
//  mapViewController.swift
//  hh
//
//  Created by Teodoro Gomes on 09/08/2018.
//  Copyright © 2018 Teodoro Gomes. All rights reserved.
//

import UIKit
import MapKit

class mapViewController: UIViewController ,CLLocationManagerDelegate , MKMapViewDelegate{

    @IBOutlet weak var map: MKMapView!
    let manager = CLLocationManager()
    var myLocation:CLLocationCoordinate2D = CLLocationCoordinate2DMake(0,0)
    
    
    override func viewDidLoad() {
        super.viewDidLoad()

       
        
        
        
        //Location Manager
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyBest
        manager.requestWhenInUseAuthorization()
        manager.startUpdatingLocation()
        
    }
    
    @IBAction func getUserLocation(_ sender: Any) {
        let span :MKCoordinateSpan = MKCoordinateSpanMake(0.01,0.01)
        let region:MKCoordinateRegion = MKCoordinateRegionMake(myLocation, span)
        map.setRegion(region, animated: true)
    }
    

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
       let location = locations[0]
       myLocation = CLLocationCoordinate2DMake(location.coordinate.latitude, location.coordinate.longitude)
       self.map.showsUserLocation = true
    }
}
