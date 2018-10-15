//
//  mapViewController.swift
//  hh
//
//  Created by Teodoro Gomes on 09/08/2018.
//  Copyright © 2018 Teodoro Gomes. All rights reserved.
//

import UIKit
import MapKit
import FirebaseDatabase
import FirebaseAuth
import Foundation


class mapViewController: UIViewController ,CLLocationManagerDelegate , MKMapViewDelegate , UISearchBarDelegate{
    
    @IBOutlet weak var filtersView: UIView!
    @IBOutlet weak var ageSlider: UISlider!
    @IBOutlet weak var sexFilter: UISegmentedControl!
    @IBOutlet weak var ageFilterLabel: UILabel!
    @IBOutlet weak var stepsFilterLabel: UILabel!
    let myGroup = DispatchGroup()
    var annoLocation = ""
    
    var ref:DatabaseReference!
   
    
    @IBAction func searchButton(_ sender: Any) {
        let searchController = UISearchController(searchResultsController: nil)
        searchController.searchBar.delegate = self
        present(searchController,animated: true,completion: nil)
    }
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        UIApplication.shared.beginIgnoringInteractionEvents()
        
        //Activity indicator
        
        let activityIndicator = UIActivityIndicatorView()
        activityIndicator.activityIndicatorViewStyle = UIActivityIndicatorViewStyle.whiteLarge
        activityIndicator.center = self.view.center
        activityIndicator.hidesWhenStopped = true
        activityIndicator.startAnimating()
        
        self.view.addSubview(activityIndicator)
        
        //Hide SearchBar
        searchBar.resignFirstResponder()
        dismiss(animated: true, completion: nil)
        
        //Create the Search Request
        let searchRequest = MKLocalSearchRequest()
        searchRequest.naturalLanguageQuery = searchBar.text
        
        let activitySearch = MKLocalSearch(request: searchRequest)
        
        activitySearch.start { (response, error) in
            
            activityIndicator.stopAnimating()
            UIApplication.shared.endIgnoringInteractionEvents()
            
            if response == nil {
                print("Error")
            }else{
                
                
                //Getting Data
                let latidude = response?.boundingRegion.center.latitude
                let longitude = response?.boundingRegion.center.longitude
                
                
                
                //Zooming Annotation
                let coordinate:CLLocationCoordinate2D = CLLocationCoordinate2DMake(latidude!, longitude!)
                let span:MKCoordinateSpan = MKCoordinateSpanMake(0.1, 0.1)
                let region = MKCoordinateRegionMake(coordinate, span)
                self.map.setRegion(region, animated: true)
            }
        }
    }
    

    
    @IBOutlet weak var map: MKMapView!
    let manager = CLLocationManager()
    var myLocation:CLLocationCoordinate2D = CLLocationCoordinate2DMake(0,0)
    
    override func viewDidAppear(_ animated: Bool) {
        map.removeAnnotations(self.map.annotations)
        addAnnotations()
        switch (UserDefaults.standard.integer(forKey: "mapType")) {
        case 0:
            map.mapType = .standard
        case 1:
            map.mapType = .satellite
        case 2:
            map.mapType = .hybrid
        default:
            map.mapType = .standard
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        ref = Database.database().reference()
       addAnnotations()
        map.delegate = self
        
        
        //Location Manager
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyBest
        manager.requestWhenInUseAuthorization()
        manager.startUpdatingLocation()
        
        
    }
    
    func addAnnotations(){
        ref.child("data").observe(.value) { (snapshot) in
            for child in snapshot.children.allObjects as! [DataSnapshot]{
                guard let dict = child.value as? [String: Any] else { continue }
                
                //ANNOTATIONS HERE
                
                
                
                let annotation = MKPointAnnotation()
                annotation.title = dict["Username"] as? String
                annotation.coordinate = CLLocationCoordinate2DMake(Double(dict["Lati"] as! String)!, Double(dict["Long"] as! String)!)
                annotation.subtitle = "Steps: \(String(describing: dict["Steps"]!))"
             
//
                
                self.map.addAnnotation(annotation)
            }
        
        }
        
        
        
        
    }
    
    @IBAction func getUserLocation(_ sender: Any) {
        if(map.showsUserLocation){
            self.map.showsUserLocation = false
        }else{
            let span :MKCoordinateSpan = MKCoordinateSpanMake(0.01,0.01)
            let region:MKCoordinateRegion = MKCoordinateRegionMake(myLocation, span)
            map.setRegion(region, animated: true)
            self.map.showsUserLocation = true
        }
       
    }
    

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
       let location = locations[0]
       myLocation = CLLocationCoordinate2DMake(location.coordinate.latitude, location.coordinate.longitude)
       
    }
    
    
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        if annotation is MKUserLocation {
            return nil
        }
    
        
        let identifier = "marker"
        var view: MKMarkerAnnotationView
        
        if let dequeuedView = mapView.dequeueReusableAnnotationView(withIdentifier: identifier)
            as? MKMarkerAnnotationView {
            dequeuedView.annotation = annotation
            view = dequeuedView
        } else {
            
            view = MKMarkerAnnotationView(annotation: annotation, reuseIdentifier: identifier)
            view.canShowCallout = true
            view.calloutOffset = CGPoint(x: -5, y: 5)
            let button = UIButton(type: .detailDisclosure)
            button.addTarget(self, action: #selector(infoClicked), for: .touchUpInside)
            view.rightCalloutAccessoryView = button
            
        }
        
       
        
        
        //Steps - Filter
        
        

        
        if(annotation.title == Auth.auth().currentUser?.displayName ){
            view.markerTintColor = UIColor.green
        }else{
            if(UserDefaults.standard.bool(forKey: "trackFriend")){
                view.markerTintColor = UIColor.red
            }else{
                view.isHidden = true
            }
            
        }
      
        
        return view
        
    }
    
    @objc func infoClicked(){
        performSegue(withIdentifier: "infoSegue", sender: self)
    }
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        let vc = segue.destination as? infoViewController
        vc?.dataID = annoLocation
        
    }
    func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
        let loc = (view.annotation?.coordinate.latitude)! + (view.annotation?.coordinate.longitude)!
        annoLocation = String(loc)
        
    }
    
    //FILTERS

    @IBAction func openFilterView(_ sender: UIButton) {
        
        if filtersView.isHidden {
            addAnnotations()
            filtersView.isHidden = false
            sender.setTitle("Save", for: .normal)
        }else{
            useFilter { (annotations) in
               
                self.map.removeAnnotations(annotations)
            }
         
            filtersView.isHidden = true
            sender.setTitle("Filters", for: .normal)
        }
        
    }
    
    
    @IBAction func stepsFilter(_ sender: UISlider) {
        sender.value = round(sender.value)
        stepsFilterLabel.text = String(Int(sender.value))
    }
    
    @IBAction func ageFilter(_ sender: UISlider) {
        sender.value = round(sender.value)
        ageFilterLabel.text = String(Int(sender.value))
    }
    
    
    func useFilter(completion: @escaping (_ annotations: [MKAnnotation] ) -> Void){
        
        var annotations:[MKAnnotation] = []
        annotations.removeAll()
        for annotation in self.map.annotations {
            // User - Filters
            self.ref.child("Users").queryOrdered(byChild: "Username").queryEqual(toValue: annotation.title!).observeSingleEvent(of: .value) { (snapshot) in
                for child in snapshot.children{
                    let snap = child as! DataSnapshot
                    let dict = snap.value as! [String: Any]
                    let age = dict["Age"] as! String
                    let sex = dict["Sex"] as! Int
                    
                    if(Int(age)! > Int(self.ageSlider.value)) {
                        annotations.append(annotation)
                    }
                    if self.sexFilter.selectedSegmentIndex != 2 {
                        if( sex != self.sexFilter.selectedSegmentIndex){
                            annotations.append(annotation)
                        }
                    }
                    let steps = annotation.subtitle.unsafelyUnwrapped?.split(separator: " ")
                    let stepsInt = Int(steps![1])
                    let stepsFromFilter = Int(self.stepsFilterLabel.text!)
                    
                    if( stepsInt! > stepsFromFilter!){
                       annotations.append(annotation)
                    }
                }
                completion(annotations)
               
            }
            
        }
        
        
        
        
        
    }
}
